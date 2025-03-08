import { APIGatewayAuthorizerResult, APIGatewayTokenAuthorizerEvent } from 'aws-lambda';
import jwt from 'jsonwebtoken';
import jwksClient from 'jwks-rsa';
import { Logger } from '@aws-lambda-powertools/logger';

// Initialisation du logger avec la librairie installée précédemment aws-lambda-powertools
const logger = new Logger({ serviceName: 'lambda-authorizer' });

// Définition de la fonction lambdaHandler qui sera appelée par l'API Gateway
export const lambdaHandler = async (event: APIGatewayTokenAuthorizerEvent): Promise<APIGatewayAuthorizerResult> => {
    logger.info('Le processus authorization commence ...');

    // Vérification des variables d'environnement nécessaires pour le processus d'authorization, elles sont définies dans le fichier [infra-as-code/modules/common/03-lambda-authorizer.lambda.tf]().
    if (
        process.env.AUDIENCE === undefined ||
        process.env.JWKS_URI === undefined ||
        process.env.ISSUER_URI === undefined
    ) {
        throw new Error("La variable d'environnement doit contenir AUDIENCE ou JWKS_URI ou ISSUER_URI ");
    }

    // Récupération du token d'authentification depuis l'événement
    logger.debug('Event', { event });
    const token = event.authorizationToken.replace('Bearer ', '');

    // Initialisation du client JWKS avec l'URI JWKS
    const client = jwksClient({ jwksUri: process.env.JWKS_URI });

    try {
        // On commence par décoder le token pour récupérer les informations nécessaires pour la vérification
        const decodedToken = jwt.decode(token, { complete: true });
        logger.debug('Decoded Token', { decodedToken });

        // Récupération de l'audience et de l'issuer depuis le token décodé
        const audience: string = decodedToken?.['payload']['aud'];
        const issuer: string = decodedToken?.['payload']['iss'];

        // Récupération de la clé publique depuis le JWKS avec l'ID de la clé (kid)
        const key = await client.getSigningKey(decodedToken?.['header']['kid']);

        // Vérification du token avec la clé publique
        jwt.verify(token, key.getPublicKey());

        // On vérifie que l'audience et l'issuer sont corrects, il est possible de pousser encore plus loin en vérifiant les scopes ou les rôles
        if (audience !== process.env.AUDIENCE) {
            throw new Error('Invalid audience');
        } else if (issuer !== process.env.ISSUER_URI) {
            throw new Error('Invalid issuer');
        }

        // Avec le principe de lambda Authorizer, l'Api attend après une réponse de type IAM Policy
    } catch (err) {
        logger.error('Error', { err });

        return {
            principalId: 'user',
            policyDocument: {
                Version: '2012-10-17',
                Statement: [
                    {
                        Action: 'execute-api:Invoke',
                        Effect: 'Deny',
                        Resource: event.methodArn,
                    },
                ],
            },
        };
    }

    logger.info('Utilisateur ou service authorise');
    return {
        principalId: 'user',
        policyDocument: {
            Version: '2012-10-17',
            Statement: [
                {
                    Action: 'execute-api:Invoke',
                    Effect: 'Allow',
                    Resource: event.methodArn,
                },
            ],
        },
    };
};

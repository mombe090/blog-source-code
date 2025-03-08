import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import type { GetItemOutput } from '@aws-sdk/client-dynamodb';
import { DynamoDBClient, GetItemCommand } from '@aws-sdk/client-dynamodb';
import type { SendMessageResult } from '@aws-sdk/client-sqs';
import { SendMessageCommand, SQSClient } from '@aws-sdk/client-sqs';
import * as process from 'node:process';
import { Logger } from '@aws-lambda-powertools/logger';

const logger = new Logger({ serviceName: 'get-account-info' });

const awsConfig = {
    region: process.env.REGION,
};

export const lambdaHandler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
    logger.debug('evenement recu', { event });

    try {
        const msisdn: string = event.pathParameters?.msisdn;

        // Validation de la presence du numero de telephone dans la requete
        if (!msisdn) {
            logger.error('Le numero de telephone est requis');
            return getApiGatewayProxyResult(400, { message: 'Le numero de telephone est requis' });
        }

        // Verification si le numéro existe en base de données
        const accountInfo = await getAccountInfo(msisdn);

        if (!accountInfo.Item) {
            logger.debug('aucun de compte pour ce numero', { msisdn });
            logger.debug('Ajout de message a la queue de creation de compte', { msisdn });

            // Ajouter les informations pour initialiser le compte dans la file d'attente, s'il n'existe pas
            await putMessageToInitAccountQueue(getCloudEventFromContext(event));

            logger.debug('Message ajoute avec succes', { msisdn });

            return getApiGatewayProxyResult(200, {
                message:
                    "Vous n'avez pas encore de compte de Paiement Mobile, un message vous sera envoye par SMS pour l'initialiser",
            });
        }

        return getApiGatewayProxyResult(200, {
            message: 'account info',
            data: {'msisdn': accountInfo.Item.msisdn.S, balance: accountInfo.Item.balance.N}
        });
    } catch (err) {
        logger.error(err);
        return getApiGatewayProxyResult(500, {
            message: "Une erreur s'est produite lors de la recuperation des informations du compte",
        });
    }
};

//Fonction charger de recuperer les informations du compte dans la table dynamoDB
export const getAccountInfo = async (msisdn: string): Promise<GetItemOutput> => {
    const client = new DynamoDBClient(awsConfig);

    const command = new GetItemCommand({
        TableName: process.env.TABLE_NAME,
        Key: {
            msisdn: { S: msisdn },
        },
    });
    return await client.send(command);
};

// Fonction chargée d'envoyer un message à la file d'attente SQS pour la création de compte
export const putMessageToInitAccountQueue = async (body: any): Promise<SendMessageResult> => {
    const client = new SQSClient({ awsConfig });

    const command = new SendMessageCommand({
        QueueUrl: process.env.INIT_ACCOUNT_QUEUE_URL,
        DelaySeconds: 10,
        MessageAttributes: {
            author: {
                DataType: 'String',
                StringValue: 'Mombesoft',
            },
            blogUrl: {
                DataType: 'String',
                StringValue: 'https://mombe090.github.io',
            },
        },
        MessageBody: JSON.stringify(body),
    });

    return await client.send(command);
};

// On utilise cloudEvent pour passer les messages entre les services
// voir https://github.com/cloudevents/spec/blob/v1.0.2/cloudevents/spec.md#example
export const getCloudEventFromContext = (event: APIGatewayProxyEvent) => {
    const date = new Date(event.requestContext.requestTimeEpoch);

    return {
        specversion: '1.0',
        type: 'gn.mombesoft.fintech-solution.get-account-info',
        source: 'https://github.com/mombe090/fintech-solution/spec/pull', //remplacer par votre spec
        subject: 'get account info',
        id: event.requestContext.requestId,
        time: date.toISOString(),
        datacontenttype: 'application/json',
        data: {
            msisdn: event.pathParameters?.msisdn,
        },
    };
};

export const getApiGatewayProxyResult = (statusCode: number, body: any): APIGatewayProxyResult => {
    return {
        statusCode,
        body: JSON.stringify(body),
    };
};

import { SSMClient, GetParameterCommand, GetParameterResult } from '@aws-sdk/client-ssm';
import { DynamoDBClient, PutItemCommand, PutItemOutput } from '@aws-sdk/client-dynamodb';
import { SESClient, SendEmailCommand } from '@aws-sdk/client-ses';
import * as process from 'node:process';
import { Logger } from '@aws-lambda-powertools/logger';
import type { SendEmailRequest, SendEmailResponse } from '@aws-sdk/client-ses';

const logger = new Logger({ serviceName: 'get-account-info' });

const awsConfig = {
    region: process.env.REGION,
};

export interface SQSRecord {
    messageId: string;
    receiptHandle: string;
    body: string;
    attributes: SQSRecordAttributes;
    messageAttributes: SQSMessageAttributes;
    md5OfBody: string;
    md5OfMessageAttributes?: string;
    eventSource: string;
    eventSourceARN: string;
    awsRegion: string;
}

export interface SQSEvent {
    Records: SQSRecord[];
}

export const lambdaHandler = async (event: SQSEvent): any => {
    try {
        const records = event.Records;

        for (const record of records) {
            const body = JSON.parse(record.body);

            logger.debug('information sur le nouveau compte', { body });

            const response = await addNewAccount(body.data.msisdn);

            logger.debug('compte créé avec succès !', { response });

            logger.info(
                'var envs : ',
                process.env.ENABLE_SMS_NOTIFICATIONS,
                process.env.ENABLE_EMAIL_NOTIFICATIONS,
                '',
            );

            if (process.env.ENABLE_SMS_NOTIFICATIONS === 'ON') {
                const credential = await getSmsProviderApiCredentials();

                const notification = await sendSmsNotificationToUser(body.data.msisdn, null, credential);
                logger.debug('notification envoyée avec succès !', { notification });
            }

            if (process.env.ENABLE_EMAIL_NOTIFICATIONS === 'ON') {
                const message = `Merci de rejoindre notre service ! Nous sommes ravis de vous avoir à bord. <br />`;

                const notification = await sendEmailNotificationToUser(
                    body.data.msisdn,
                    'Bienvenue sur notre service',
                    message,
                );

                if (notification.$metadata.httpStatusCode !== 200) {
                    logger.error(notification);
                    throw new Error("Erreur lors de l'envoi de la notification", { notification });
                } else {
                    logger.debug('notification envoyée avec succès !', { notification });
                }
            }
        }
    } catch (error) {
        logger.error({ error });
        throw new Error(error);
    }
};

export const addNewAccount = async (msisdn: string): Promise<PutItemOutput> => {
    const client = new DynamoDBClient(awsConfig);

    logger.debug("ajout d'un nouvel utilisateur avec le msisdn suivant : ", { msisdn });
    // https://github.com/aws/aws-sdk-js-v3/blob/main/lib/lib-dynamodb/README.md
    const input = {
        Item: {
            msisdn: {
                S: msisdn,
            },
            balance: {
                N: '1000',
            }, // Montant initial en GNF
            createdAt: {
                S: new Date().toISOString(),
            },
        },
        TableName: process.env.TABLE_NAME,
    };

    return await client.send(new PutItemCommand(input));
};

export const getSmsProviderApiCredentials = async (): Promise<any> => {
    const client = new SSMClient(awsConfig);
    const command = new GetParameterCommand({
        Name: process.env.SMS_PROVIDER_API_CREDENTIALS_PARAMETER_NAME,
        WithDecryption: true,
    });

    logger.info('Récupération des credentials SMS_PROVIDER_API_KEY et SMS_PROVIDER_API_SECRET');

    const response: GetParameterResult = await client.send(command);

    const { client_id, client_secret, url } = JSON.parse(response.Parameter.Value);

    if (!client_id || !client_secret || !url) {
        throw new Error('le client_id ou client_secret ou url est manquant dans le paramètre SSM');
    }

    return { client_id, client_secret, url };
};

export const sendSmsNotificationToUser = async (msisdn: string, message: string, credential): Promise<any> => {
    logger.debug(`Envoi de notification à l'utilisateur ${msisdn} avec le message ${message} via ${credential.url}`);
    const response = await fetch(credential.url, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            Authorization: `Basic ${Buffer.from(`${credential.client_id}:${credential.client_secret}`).toString(
                'base64',
            )}`,
        },
        body: JSON.stringify({
            to: [msisdn],
            sender_name: 'SMS 9080',
            message:
                message ||
                `Bonjour ceci est just un message de test, votre compte esssaie serverless fintech est active, avec un solde de 10000 frs, vous pouvez commencer à utiliser votre compte.`,
        }),
    });

    if (!response.ok) {
        logger.error(response.body);
        throw new Error('Erreur lors de l envoi de notification' + response.body);
    }

    logger.debug('Server response', { response: await response.json() });

    return await response.json();
};

export const sendEmailNotificationToUser = async (
    msisdn: string,
    title: string,
    message: string,
): Promise<SendEmailResponse> => {
    logger.debug(`Envoi de l email de notification à l'utilisateur ${msisdn} avec le message ${message} `);

    const client = new SESClient(awsConfig);

    const input: SendEmailRequest = {
        //On vérifie si on utilise un domaine personnalisé ou pas
        //Sinon on utilise l'email de destination par défaut
        Source: process.env.APPLY_CUSTOM_DOMAIN === true ? `api@${process.env.DOMAIN_NAME}` : process.env.DESTINATION_EMAIL_EMAIL,
        Destination: {
            ToAddresses: [process.env.DESTINATION_EMAIL_EMAIL],
        },
        Message: {
            Subject: {
                Data: 'Test from mombe090.github.io blog',
                Charset: 'UTF-8',
            },
            Body: {
                Html: {
                    Data: `
                    <!DOCTYPE html>
                        <html lang="en">
                        <head>
                            <meta charset="UTF-8">
                            <meta name="viewport" content="width=device-width, initial-scale=1.0">
                            <title>Mombe090.github.io blog serverless fintech mobile money tranfert sample</title>
                        </head>
                        <body style="font-family: Arial, sans-serif; background-color: #f4f4f4; margin: 0; padding: 0;">
                            <div style="width: 100%; max-width: 600px; margin: 0 auto; background-color: #ffffff; padding: 20px; box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);">
                                <div style="text-align: center; padding: 20px 0; background-color: #007bff; color: #ffffff;">
                                    <h1 style="margin: 0; font-size: 24px;">${title}</h1>
                                </div>
                                <div style="padding: 20px;">
                                    <h2 style="color: #333333; font-size: 20px; margin-top: 0;">Bonjour numéro ${msisdn},</h2>
                                    <p style="color: #666666; font-size: 16px; line-height: 1.6;"></p>
                                    <p>
                                    ${message}
                                    </p>
                                    <ul style="color: #666666; font-size: 16px; line-height: 1.6;">
                                        <li>Username: nom complet </li>
                                        <li>Email : votre email</li>
                                        
                                    </ul>
                                    <a href="https://mombe0909.github.io" target="_blank" rel="noopener noreferrer" title="https://mombe0909.github.io" style="display: inline-block; padding: 10px 20px; background-color: #007bff; color: #ffffff; text-decoration: none; border-radius: 5px; margin-top: 20px;">Lisez d'autres articles sur le blog.</a>
                                </div>
                                <div style="text-align: center; padding: 20px 0; background-color: #f8f9fa; color: #6c757d;">
                                    <p style="margin: 0; font-size: 14px;">&copy; 2025 Learn, Share, Grow. All rights reserved.</p>
                                </div>
                            </div>
                        </body>
                        </html>
                    `, // required
                    Charset: 'UTF-8',
                },
            },
        },
    };

    return await client.send(new SendEmailCommand(input));
};

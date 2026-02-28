"use strict";

const { DynamoDBClient, PutItemCommand } = require("@aws-sdk/client-dynamodb");
const { SNSClient, PublishCommand } = require("@aws-sdk/client-sns");
const { randomUUID } = require("crypto");

const REGION = process.env.REGION;
const TABLE = process.env.DYNAMODB_TABLE;
const SNS_ARN = process.env.SNS_TOPIC_ARN;
const EMAIL = process.env.TEST_EMAIL;
const REPO = process.env.GITHUB_REPO;

// sns topic is in us-east-1, always publish there regardless of executing region
const dynamo = new DynamoDBClient({ region: REGION });
const sns = new SNSClient({ region: "us-east-1" });

exports.handler = async (event) => {
  const id = randomUUID();
  const timestamp = new Date().toISOString();

  // write to regional dynamodb table
  await dynamo.send(
    new PutItemCommand({
      TableName: TABLE,
      Item: {
        id: { S: id },
        timestamp: { S: timestamp },
        region: { S: REGION },
        source: { S: "greeter-lambda" },
      },
    }),
  );

  // publish verification payload to unleash live sns topic
  const payload = {
    email: EMAIL,
    source: "Lambda",
    region: REGION,
    repo: REPO,
  };

  const snsResult = await sns.send(
    new PublishCommand({
      TopicArn: SNS_ARN,
      Message: JSON.stringify(payload),
    }),
  );
  console.log("✅ sns published:", JSON.stringify(snsResult));

  // return 200 with region info
  return {
    statusCode: 200,
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      message: `Hello from ${REGION}!`,
      region: REGION,
      id,
      timestamp,
    }),
  };
};

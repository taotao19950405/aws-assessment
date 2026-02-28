"use strict";

const { ECSClient, RunTaskCommand } = require("@aws-sdk/client-ecs");

const REGION      = process.env.REGION;
const CLUSTER_ARN = process.env.ECS_CLUSTER_ARN;
const TASK_DEF    = process.env.TASK_DEF_ARN;
const SUBNET_IDS  = (process.env.SUBNET_IDS || "").split(",").filter(Boolean);
const SG_ID       = process.env.SECURITY_GROUP_ID;

const ecs = new ECSClient({ region: REGION });

exports.handler = async (event) => {

  // trigger ecs fargate task to publish sns message
  const result = await ecs.send(new RunTaskCommand({
    cluster:        CLUSTER_ARN,
    taskDefinition: TASK_DEF,
    launchType:     "FARGATE",
    networkConfiguration: {
      awsvpcConfiguration: {
        subnets:        SUBNET_IDS,
        securityGroups: [SG_ID],
        // public subnet, no nat gateway needed
        assignPublicIp: "ENABLED",
      },
    },
  }));

  const task = result.tasks?.[0];

  return {
    statusCode: 202,
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      message:    `ECS Fargate task dispatched from ${REGION}`,
      region:     REGION,
      taskArn:    task?.taskArn ?? null,
      taskStatus: task?.lastStatus ?? "PROVISIONING",
    }),
  };
};
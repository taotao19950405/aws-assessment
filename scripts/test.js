"use strict";

const https = require("https");

// ── config ────────────────────────────────────────────────────────────────────
const USER_POOL_ID = process.env.USER_POOL_ID;
const CLIENT_ID    = process.env.CLIENT_ID;
const EMAIL        = process.env.TEST_EMAIL;
const PASSWORD     = process.env.TEST_PASSWORD;
const API_US       = process.env.API_URL_US;
const API_EU       = process.env.API_URL_EU;

if (!USER_POOL_ID || !CLIENT_ID || !API_US || !API_EU || !PASSWORD) {
  console.error("❌  missing required environment variables");
  console.error("    USER_POOL_ID, CLIENT_ID, API_URL_US, API_URL_EU, TEST_PASSWORD, TEST_EMAIL");
  process.exit(1);
}

if (!PASSWORD) {
  console.error("❌  set TEST_PASSWORD environment variable first");
  process.exit(1);
}

// ── helpers ───────────────────────────────────────────────────────────────────
function request(url, method, body, headers = {}) {
  return new Promise((resolve, reject) => {
    const parsed = new URL(url);
    const data   = body ? JSON.stringify(body) : null;
    const start  = Date.now();

    const req = https.request({
      hostname: parsed.hostname,
      path:     parsed.pathname,
      method,
      headers: {
        "Content-Type": "application/x-amz-json-1.1",
        ...(data && { "Content-Length": Buffer.byteLength(data) }),
        ...headers,
      },
    }, (res) => {
      let raw = "";
      res.on("data", (c) => (raw += c));
      res.on("end", () => {
        const latencyMs = Date.now() - start;
        try {
          resolve({ status: res.statusCode, body: JSON.parse(raw), latencyMs });
        } catch {
          resolve({ status: res.statusCode, body: raw, latencyMs });
        }
      });
    });

    req.on("error", reject);
    if (data) req.write(data);
    req.end();
  });
}

// ── step 1: authenticate with cognito ────────────────────────────────────────
async function getJwt() {
  console.log("\n🔐  authenticating with cognito...");

  const res = await request(
    "https://cognito-idp.us-east-1.amazonaws.com/",
    "POST",
    {
      AuthFlow:       "USER_PASSWORD_AUTH",
      ClientId:       CLIENT_ID,
      AuthParameters: { USERNAME: EMAIL, PASSWORD },
    },
    { "X-Amz-Target": "AWSCognitoIdentityProviderService.InitiateAuth" }
  );

  if (res.status !== 200 || !res.body?.AuthenticationResult?.IdToken) {
    console.error("❌  auth failed:", JSON.stringify(res.body, null, 2));
    process.exit(1);
  }

  console.log("✅  jwt obtained");
  return res.body.AuthenticationResult.IdToken;
}

// ── step 2 & 3: concurrent requests to both regions ──────────────────────────
async function runTests(token) {
  const auth = { Authorization: token };

  console.log("\n🚀  firing concurrent requests to both regions...\n");

  const [greetUs, greetEu, dispatchUs, dispatchEu] = await Promise.all([
    request(`${API_US}/greet`,    "GET",  null, auth),
    request(`${API_EU}/greet`,    "GET",  null, auth),
    request(`${API_US}/dispatch`, "POST", {},   { ...auth, "Content-Type": "application/json" }),
    request(`${API_EU}/dispatch`, "POST", {},   { ...auth, "Content-Type": "application/json" }),
  ]);

  const results = [
    { label: "GET /greet    → us-east-1", expected: "us-east-1", res: greetUs },
    { label: "GET /greet    → eu-west-1", expected: "eu-west-1", res: greetEu },
    { label: "POST /dispatch → us-east-1", expected: "us-east-1", res: dispatchUs },
    { label: "POST /dispatch → eu-west-1", expected: "eu-west-1", res: dispatchEu },
  ];

  let allPassed = true;

  for (const { label, expected, res } of results) {
    const returnedRegion = res.body?.region ?? "UNKNOWN";
    const regionMatch    = returnedRegion === expected;
    const statusOk       = res.status === 200 || res.status === 202;
    const passed         = regionMatch && statusOk;

    if (!passed) allPassed = false;

    console.log(`${passed ? "✅" : "❌"}  ${label}`);
    console.log(`     http ${res.status} | latency: ${res.latencyMs}ms`);
    console.log(`     region returned: ${returnedRegion} | expected: ${expected} | match: ${regionMatch ? "YES" : "NO ⚠️"}`);
    console.log();
  }

  // latency comparison
  console.log("📊  latency comparison:");
  console.log(`     /greet    us-east-1: ${greetUs.latencyMs}ms`);
  console.log(`     /greet    eu-west-1: ${greetEu.latencyMs}ms`);
  console.log(`     /dispatch us-east-1: ${dispatchUs.latencyMs}ms`);
  console.log(`     /dispatch eu-west-1: ${dispatchEu.latencyMs}ms`);

  console.log("\n" + (allPassed ? "🎉  all assertions passed!" : "💥  some assertions failed"));
  if (!allPassed) process.exit(1);
}

// ── main ──────────────────────────────────────────────────────────────────────
(async () => {
  const token = await getJwt();
  await runTests(token);
})();
const aws = require("aws-sdk");

const s3 = new aws.S3({ region: "${bucket_region}" });

const VARS = {
  assetsPath: "assets/${version}/",
};

const DataLayerScript = `window.dataLayer=[{"gtm.start":(new Date).getTime(),event:"gtm.js"}];`;
const LoadingScreenScript = `
window.onAppLoaded = function () {
  const e = document.querySelector("#app-loader");
  e && e.parentNode.removeChild(e)
},
setTimeout(function () {
  const e = document.querySelector(".loading-screen");
  e && e.classList.remove("loading-screen--hidden")
}, 250),
setTimeout(function () {
    const e = document.querySelector(".long-loading-notice");
    e && e.classList.remove("long-loading-notice--hidden")
  },
  2000)
`;

const LoadingScreenCSS = `
  <style>
  .loading-screen {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    height: 100vh;
    width: 100vw
  }

  .loading-screen--hidden {
    display: none
  }

  .loading-screen>*+* {
    margin: 24px 0 0
  }

  .loading-spinner {
    width: 32px;
    height: 32px
  }

  .long-loading-notice {
    color: #999;
    font-family: 'Open Sans', sans-serif;
    font-size: 12px
  }

  .long-loading-notice--hidden {
    visibility: hidden
  }

  .loading-spinner-circle {
    fill: #213c45;
    opacity: .2
  }

  @keyframes loading-spinner-animation {
    0%% {
      transform: rotate(0)
    }
    100%% {
      transform: rotate(360deg)
    }
  }

  .loading-spinner-pointer {
    transform-origin: 20px 20px 0;
    animation: loading-spinner-animation .5s infinite linear
  }
  </style>`;

const ApplicationConfig = {
  externalApiUrl: "${external_api_url}",
  applicationName: "${application_name}",
  entryPointUriPath: "${entrypoint_uri_path}",
  env: "production",
  location: "gcp-eu",
  mcApiUrl: "${mc_api_url}",
  revision: "",
  servedByProxy: true,

  // Set during request
  cdnUrl: null,
  frontendHost: null,
};

exports.handler = async (event, context) => {
  console.log(JSON.stringify(event, null, 4));
  const { config } = event.Records[0].cf;

  if (config.eventType == "origin-request") {
    const { request } = event.Records[0].cf;

    // Note that we use terraform templates, so keep it simple (no escaping)
    ApplicationConfig.cdnUrl =
      "https://" + config.distributionDomainName + "/" + VARS.assetsPath;
    ApplicationConfig.frontendHost = config.distributionDomainName;

    const key = VARS.assetsPath + "index.html.template";
    console.log("Retrieving template file from s3 bucket:", key);
    try {
      const s3Response = await s3
        .getObject({
          Bucket: "${bucket_name}",
          Key: key,
        })
        .promise();

      console.log(JSON.stringify(request, null, 4));
      var content = s3Response.Body.toString("utf-8");

      // Well ;-)
      content = content.split("__CDN_URL__").join(ApplicationConfig.cdnUrl);

      content = content
        .split("__APP_ENVIRONMENT__")
        .join(JSON.stringify(ApplicationConfig));

      content = content
        .split("__MC_API_URL__")
        .join(ApplicationConfig.mcApiUrl);

      content = content
        .split("__LOADING_SCREEN_JS__")
        .join(LoadingScreenScript);

      content = content.split("__DATALAYER_JS__").join(DataLayerScript);

      content = content.split("__GTM_SCRIPT__").join("");
      content = content.split("__LOADING_SCREEN_CSS__").join(LoadingScreenCSS);

      console.log(content);

      return {
        status: "200",
        statusDescription: "OK",
        body: content,
        headers: {
          "content-type": [{ value: "text/html;charset=UTF-8" }],
        },
      };
    } catch (err) {
      console.error(err);
      return {
        status: "404",
        statusDescription: "Not Found",
      };
    }
  } else if (config.eventType == "origin-response") {
    const { response } = event.Records[0].cf;
    const { headers } = response;

    headers["strict-transport-security"] = [
      { key: "Strict-Transport-Security", value: "max-age=31536000" },
    ];
    headers["x-xss-protection"] = [
      { key: "X-XSS-Protection", value: "1; mode=block" },
    ];
    headers["x-content-type-options"] = [
      { key: "X-Content-Type-Options", value: "nosniff" },
    ];
    headers["x-frame-options"] = [{ key: "X-Frame-Options", value: "DENY" }];
    headers["referrer-policy"] = [
      { key: "Referrer-Policy", value: "same-origin" },
    ];
    headers["cache-control"] = [{ key: "Cache-Control", value: "no-cache" }];

    return response;
  }
};

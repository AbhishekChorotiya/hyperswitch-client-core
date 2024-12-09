const express = require('express');
const cors = require('cors');
const app = express();
app.use(cors());
app.use(express.static('./dist'));
app.use(express.json());

require('dotenv').config({ path: './.env' });

try {
  var hyper = require('@juspay-tech/hyperswitch-node')(
    process.env.HYPERSWITCH_SECRET_KEY,
  );
} catch (err) {
  console.error('process.env.HYPERSWITCH_SECRET_KEY not found, ', err.message);
  process.exit(0);
}

app.get('/create-payment-intent', async (req, res) => {
  try {
    var paymentIntent = await hyper.paymentIntents.create({
      "amount": 6500,
      "order_details": [
        {
          "product_name": "Apple iphone 15",
          "quantity": 1,
          "amount": 6500
        }
      ],
      "currency": "USD",
      "confirm": false,
      "capture_method": "automatic",
      "authentication_type": "three_ds",
      "setup_future_usage": "on_session",
      "request_external_three_ds_authentication": false,
      "email": "user@gmail.com",
      "description": "Hello this is description",
      "profile_id": "pro_E6k4XxWE3fVzTIYDMzJa",
      "shipping": {
        "address": {
          "state": "California",
          "city": "Banglore",
          "country": "US",
          "line1": "sdsdfsdf",
          "line2": "hsgdbhd",
          "line3": "alsksoe",
          "zip": "571201",
          "first_name": "John",
          "last_name": "Doe"
        },
        "phone": {
          "number": "123456789",
          "country_code": "+1"
        }
      },
      "connector_metadata": {
        "noon": {
          "order_category": "applepay"
        }
      },
      "metadata": {
        "udf1": "value1",
        "new_customer": "true",
        "login_date": "2019-09-10T10:11:12Z"
      },
      "billing": {
        "address": {
          "line1": "1467",
          "line2": "Harrison Street",
          "line3": "Harrison Street",
          "city": "San Fransico",
          "state": "California",
          "zip": "94122",
          "country": "US",
          "first_name": "joseph",
          "last_name": "Doe"
        },
        "phone": {
          "number": "8056594427",
          "country_code": "+91"
        }
      },
      "customer_id": "hyperswitch_sdk_demo_id"
    });

    // Send publishable key and PaymentIntent details to client
    res.send({
      publishableKey: process.env.HYPERSWITCH_PUBLISHABLE_KEY,
      clientSecret: paymentIntent.client_secret,
    });
  } catch (err) {
    return res.status(400).send({
      error: {
        message: err.message,
      },
    });
  }
});

app.get('/create-ephemeral-key', async (req, res) => {
  try {
    const response = await fetch(
      `https://sandbox.hyperswitch.io/ephemeral_keys`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'api-key': process.env.HYPERSWITCH_SECRET_KEY,
        },
        body: JSON.stringify({ customer_id: "hyperswitch_sdk_demo_id" }),
      },
    );
    const ephemeralKey = await response.json();

    res.send({
      ephemeralKey: ephemeralKey.secret,
    });
  } catch (err) {
    return res.status(400).send({
      error: {
        message: err.message,
      },
    });
  }
});

app.get('/payment_methods', async (req, res) => {
  try {
    const response = await fetch(
      `https://sandbox.hyperswitch.io/payment_methods`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'api-key': process.env.HYPERSWITCH_SECRET_KEY,
        },
        body: JSON.stringify({ customer_id: 'hyperswitch_sdk_demo_id' }),
      },
    );
    const json = await response.json();

    res.send({
      customerId: json.customer_id,
      paymentMethodId: json.payment_method_id,
      clientSecret: json.client_secret,
      publishableKey: process.env.HYPERSWITCH_PUBLISHABLE_KEY,
    });
  } catch (err) {
    return res.status(400).send({
      error: {
        message: err.message,
      },
    });
  }
});

app.listen(5252, () =>
  console.log(`Node server listening at http://localhost:5252`),
);

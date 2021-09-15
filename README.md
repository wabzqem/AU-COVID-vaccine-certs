#  AU COVID-19 Vaccine iOS app

## What
This is an application for iOS and macOS that lets you log in to myGov, fetches your medicare information and displays a QR code with your vaccine data, in the same format that EU apps use. QR Codes created with this app can be verified and cannot be forged. You can only get obtain a QR code if you have been vaccinated, and the system is therefore much more trustworthy than what our government has provided us with.

You can use this application as a wallet, or scan the QR code from another covid certificate wallet application. Other apps developed by the EU will show a warning saying the signature is not valid, but wallet apps will still hold the certificates and be verifiable by the corresponding AU verification app.

This is to be used in combination with the Verifier application, which has the corresponding public key to verify certificates.


## How
The app logs in to medicare the same way that the government's Express Plus Medicare mobile app does. To fetch the QR code (and only to fetch the QR code), it then sends a request to https://medicare.whatsbeef.net, which proxies the request to medicare. As the response comes back, the proxy component converts the response into the EU QR code format, signs it with its private key, and sends it back to the app in image format.

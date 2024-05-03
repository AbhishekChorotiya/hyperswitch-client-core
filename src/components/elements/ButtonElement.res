open ReactNative
open PaymentMethodListType
open GooglePayType

external parser: paymentMethodData => JSON.t = "%identity"
external parser2: GooglePayType.requestType => JSON.t = "%identity"

type item = {
  linearGradientColorTuple: option<ThemebasedStyle.buttonColorConfig>,
  name: string,
  iconName: string,
}

@react.component
let make = (
  ~walletType: PaymentMethodListType.payment_method_types_wallet,
  ~sessionObject,
  ~confirm=false,
  ~buttonSize=?,
) => {
  let (allApiData, _) = React.useContext(AllApiDataContext.allApiDataContext)
  let (_, setLoading) = React.useContext(LoadingContext.loadingContext)
  let useAlerts = AlertHook.useAlerts()

  let useHandleSuccessFailure = AllPaymentHooks.useHandleSuccessFailure()
  let (buttomFlex, _) = React.useState(_ => Animated.Value.create(1.))
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)

  let logger = LoggerHook.useLoggerHook()
  let {
    paypalButonColor,
    googlePayButtonColor,
    applePayButtonColor,
    buttonBorderRadius,
  } = ThemebasedStyle.useThemeBasedStyle()

  let useRedirectHook = AllPaymentHooks.useRedirectHook()
  // let (show, setShow) = React.useState(_ => true)
  let animateFlex = (~flexval, ~value, ~endCallback=() => (), ()) => {
    Animated.timing(
      flexval,
      Animated.Value.Timing.config(
        ~toValue={value->Animated.Value.Timing.fromRawValue},
        ~isInteraction=true,
        ~useNativeDriver=false,
        ~delay=0.,
        (),
      ),
    )->Animated.start(~endCallback=_ => {endCallback()}, ())
  }

  let {linearGradientColorTuple, name, iconName} = switch (
    walletType.payment_method_type_wallet,
    walletType.payment_experience[0]->Option.map(paymentExperience =>
      paymentExperience.payment_experience_type_decode
    ),
  ) {
  | (payment_method_type_wallet, Some(INVOKE_SDK_CLIENT)) =>
    switch payment_method_type_wallet {
    | PAYPAL => {
        linearGradientColorTuple: Some(paypalButonColor),
        name: "PayPal",
        iconName: "paypal",
      }
    | GOOGLE_PAY => {
        linearGradientColorTuple: Some(googlePayButtonColor),
        name: "Google Pay",
        iconName: "googlePayWalletBtn",
      }
    | APPLE_PAY => {
        linearGradientColorTuple: Some(applePayButtonColor),
        name: "Apple Pay",
        iconName: "applePayWalletBtn",
      }
    | _ => {
        linearGradientColorTuple: None,
        name: "",
        iconName: "",
      }
    }
  | (PAYPAL, Some(REDIRECT_TO_URL)) => {
      linearGradientColorTuple: Some(paypalButonColor),
      name: "PayPal",
      iconName: "paypal",
    }
  | _ => {
      linearGradientColorTuple: None,
      name: "",
      iconName: "",
    }
  }

  let processRequest = (~payment_method_data, ~walletTypeAlt=?, ()) => {
    let walletType = switch walletTypeAlt {
    | Some(wallet) => wallet
    | None => walletType
    }

    let errorCallback = (~errorMessage, ~closeSDK, ()) => {
      logger(
        ~logType=INFO,
        ~value="",
        ~category=USER_EVENT,
        ~eventName=PAYMENT_FAILED,
        ~paymentMethod={walletType.payment_method_type},
        ~paymentExperience=?walletType.payment_experience[0]->Option.map(paymentExperience =>
          paymentExperience.payment_experience_type_decode
        ),
        (),
      )
      if !closeSDK {
        setLoading(FillingDetails)
      }
      useHandleSuccessFailure(~apiResStatus=errorMessage, ~closeSDK, ())
    }
    let responseCallback = (~paymentStatus: LoadingContext.sdkPaymentState, ~status) => {
      logger(
        ~logType=INFO,
        ~value="",
        ~category=USER_EVENT,
        ~eventName=PAYMENT_DATA_FILLED,
        ~paymentMethod={walletType.payment_method_type},
        ~paymentExperience=?walletType.payment_experience[0]->Option.map(paymentExperience =>
          paymentExperience.payment_experience_type_decode
        ),
        (),
      )
      logger(
        ~logType=INFO,
        ~value="",
        ~category=USER_EVENT,
        ~eventName=PAYMENT_ATTEMPT,
        ~paymentMethod=walletType.payment_method_type,
        ~paymentExperience=?walletType.payment_experience[0]->Option.map(paymentExperience =>
          paymentExperience.payment_experience_type_decode
        ),
        (),
      )
      switch paymentStatus {
      | PaymentSuccess => {
          logger(
            ~logType=INFO,
            ~value="",
            ~category=USER_EVENT,
            ~eventName=PAYMENT_SUCCESS,
            ~paymentMethod={walletType.payment_method_type},
            ~paymentExperience=?walletType.payment_experience[0]->Option.map(paymentExperience =>
              paymentExperience.payment_experience_type_decode
            ),
            (),
          )
          setLoading(PaymentSuccess)
          animateFlex(
            ~flexval=buttomFlex,
            ~value=0.01,
            ~endCallback=() => {
              setTimeout(() => {
                useHandleSuccessFailure(~apiResStatus=status, ())
              }, 1500)->ignore
            },
            (),
          )
        }
      | _ => useHandleSuccessFailure(~apiResStatus=status, ())
      }
    }

    let body: redirectType = {
      client_secret: nativeProp.clientSecret,
      return_url: ?switch nativeProp.hyperParams.appId {
      | Some(id) => Some(id ++ ".hyperswitch://")
      | None => None
      },
      // customer_id: ?switch nativeProp.configuration.customer {
      // | Some(customer) => customer.id
      // | None => None
      // },
      payment_method: walletType.payment_method,
      payment_method_type: walletType.payment_method_type,
      payment_experience: ?walletType.payment_experience[0]->Option.map(paymentExperience =>
        paymentExperience.payment_experience_type
      ),
      connector: ?walletType.payment_experience[0]->Option.map(paymentExperience =>
        paymentExperience.eligible_connectors
      ),
      payment_method_data,
      billing: ?nativeProp.configuration.defaultBillingDetails,
      shipping: ?nativeProp.configuration.shippingDetails,
      setup_future_usage: "off_session",
      payment_type: ?allApiData.paymentType,
      customer_acceptance: {
        acceptance_type: "online",
        accepted_at: Date.now()->Date.fromTime->Date.toISOString,
        online: {
          ip_address: ?nativeProp.hyperParams.ip,
          user_agent: ?nativeProp.hyperParams.userAgent,
        },
      },
      // mandate_data: ?(
      //   allApiData.mandateType != NORMAL
      //     ? Some({
      //         customer_acceptance: {
      //           acceptance_type: "online",
      //           accepted_at: Date.now()->Date.fromTime->Date.toISOString,
      //           online: {
      //             ip_address: ?nativeProp.hyperParams.ip,
      //             user_agent: ?nativeProp.hyperParams.userAgent,
      //           },
      //         },
      //       })
      //     : None
      // ),
      browser_info: {
        user_agent: ?nativeProp.hyperParams.userAgent,
      },
    }

    useRedirectHook(
      ~body=body->JSON.stringifyAny->Option.getOr(""),
      ~publishableKey=nativeProp.publishableKey,
      ~clientSecret=nativeProp.clientSecret,
      ~errorCallback,
      ~responseCallback,
      ~paymentMethod=walletType.payment_method_type,
      ~paymentExperience=?walletType.payment_experience[0]->Option.map(paymentExperience =>
        paymentExperience.payment_experience_type_decode
      ),
      (),
    )
  }

  let confirmPayPal = var => {
    let paymentData = var->PaymentConfirmTypes.itemToObjMapperJava
    switch paymentData.error {
    | "" =>
      let json = paymentData.paymentMethodData->JSON.Encode.string
      let paymentData = [("token", json)]->Dict.fromArray->JSON.Encode.object
      let payment_method_data =
        [
          (
            walletType.payment_method,
            [(walletType.payment_method_type ++ "_sdk", paymentData)]
            ->Dict.fromArray
            ->JSON.Encode.object,
          ),
        ]
        ->Dict.fromArray
        ->JSON.Encode.object
      processRequest(~payment_method_data, ())
    | "User has canceled" =>
      setLoading(FillingDetails)
      useAlerts(~errorType="warning", ~message="Payment was Cancelled")
    | err => useAlerts(~errorType="error", ~message=err)
    }
  }

  let confirmGPay = var => {
    let paymentData = var->PaymentConfirmTypes.itemToObjMapperJava
    switch paymentData.error {
    | "" =>
      let json = paymentData.paymentMethodData->JSON.parseExn
      let obj = json->Utils.getDictFromJson->itemToObjMapper
      let payment_method_data =
        [
          (
            walletType.payment_method,
            [(walletType.payment_method_type, obj.paymentMethodData->parser)]
            ->Dict.fromArray
            ->JSON.Encode.object,
          ),
        ]
        ->Dict.fromArray
        ->JSON.Encode.object
      processRequest(~payment_method_data, ())
    | "Cancel" =>
      setLoading(FillingDetails)
      useAlerts(~errorType="warning", ~message="Payment was Cancelled")
    | err =>
      setLoading(FillingDetails)
      useAlerts(~errorType="error", ~message=err)
    }
  }

  let confirmApplePay = var => {
    switch var
    ->Dict.get("status")
    ->Option.getOr(JSON.Encode.null)
    ->JSON.Decode.string
    ->Option.getOr("") {
    | "Cancelled" =>
      setLoading(FillingDetails)
      useAlerts(~errorType="warning", ~message="Cancelled")
    | "Failed" =>
      setLoading(FillingDetails)
      useAlerts(~errorType="error", ~message="Failed")
    | "Error" =>
      setLoading(FillingDetails)
      useAlerts(~errorType="warning", ~message="Error")
    | _ =>
      let payment_data = var->Dict.get("payment_data")->Option.getOr(JSON.Encode.null)

      let payment_method = var->Dict.get("payment_method")->Option.getOr(JSON.Encode.null)

      let transaction_identifier =
        var->Dict.get("transaction_identifier")->Option.getOr(JSON.Encode.null)

      if transaction_identifier->JSON.stringify == "Simulated Identifier" {
        setLoading(FillingDetails)
        useAlerts(
          ~errorType="warning",
          ~message="Apple Pay is not supported in Simulated Environment",
        )
      } else {
        let paymentData =
          [
            ("payment_data", payment_data),
            ("payment_method", payment_method),
            ("transaction_identifier", transaction_identifier),
          ]
          ->Dict.fromArray
          ->JSON.Encode.object

        let payment_method_data =
          [
            (
              walletType.payment_method,
              [(walletType.payment_method_type, paymentData)]->Dict.fromArray->JSON.Encode.object,
            ),
          ]
          ->Dict.fromArray
          ->JSON.Encode.object
        processRequest(~payment_method_data, ())
      }
    }
  }

  let pressHandler = () => {
    setLoading(ProcessingPayments)
    logger(
      ~logType=INFO,
      ~value=walletType.payment_method_type,
      ~category=USER_EVENT,
      ~paymentMethod=walletType.payment_method_type,
      ~eventName=PAYMENT_METHOD_CHANGED,
      ~paymentExperience=?walletType.payment_experience[0]->Option.map(paymentExperience =>
        paymentExperience.payment_experience_type_decode
      ),
      (),
    )
    switch walletType.payment_experience[0]->Option.map(paymentExperience =>
      paymentExperience.payment_experience_type_decode
    ) {
    | Some(INVOKE_SDK_CLIENT) =>
      switch walletType.payment_method_type_wallet {
      | GOOGLE_PAY =>
        HyperModule.launchGPay(
          GooglePayType.getGpayToken(~obj=sessionObject, ~appEnv=nativeProp.env),
          confirmGPay,
        )
      | PAYPAL =>
        if sessionObject.session_token !== "" && ReactNative.Platform.os == #android {
          PaypalModule.launchPayPal(sessionObject.session_token, confirmPayPal)
        } else {
          let redirectData = []->Dict.fromArray->JSON.Encode.object
          let payment_method_data =
            [
              (
                walletType.payment_method,
                [(walletType.payment_method_type ++ "_redirect", redirectData)]
                ->Dict.fromArray
                ->JSON.Encode.object,
              ),
            ]
            ->Dict.fromArray
            ->JSON.Encode.object
          let altPaymentExperience =
            walletType.payment_experience->Array.find(x =>
              x.payment_experience_type_decode === REDIRECT_TO_URL
            )
          let walletTypeAlt = {
            ...walletType,
            payment_experience: [
              altPaymentExperience->Option.getOr({
                payment_experience_type: "",
                payment_experience_type_decode: NONE,
                eligible_connectors: [],
              }),
            ],
          }
          // when session token for paypal is absent, switch to redirect flow
          processRequest(~payment_method_data, ~walletTypeAlt, ())
        }
      | APPLE_PAY =>
        if (
          sessionObject.session_token_data == JSON.Encode.null ||
            sessionObject.payment_request_data == JSON.Encode.null
        ) {
          setLoading(FillingDetails)
          useAlerts(~errorType="warning", ~message="Waiting for Sessions API")
        } else {
          HyperModule.launchApplePay(
            [
              ("session_token_data", sessionObject.session_token_data),
              ("payment_request_data", sessionObject.payment_request_data),
            ]
            ->Dict.fromArray
            ->JSON.Encode.object
            ->JSON.stringify,
            confirmApplePay,
          )
        }
      | _ => ()
      }
    | Some(REDIRECT_TO_URL) =>
      let redirectData = []->Dict.fromArray->JSON.Encode.object
      let payment_method_data =
        [
          (
            walletType.payment_method,
            [(walletType.payment_method_type ++ "_redirect", redirectData)]
            ->Dict.fromArray
            ->JSON.Encode.object,
          ),
        ]
        ->Dict.fromArray
        ->JSON.Encode.object
      processRequest(~payment_method_data, ())
    | _ => ()
    }
  }

  React.useEffect1(_ => {
    if confirm {
      pressHandler()
    }
    None
  }, [confirm])

  <>
    <CustomButton
      borderRadius=buttonBorderRadius
      borderWidth=0.
      linearGradientColorTuple
      leftIcon=CustomIcon(<Icon name=iconName width=120. height=115. />)
      onPress={_ => pressHandler()}
      name
      ?buttonSize
    />
    <Space height=8. />
  </>
}
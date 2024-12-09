open ReactNative
open Style

type fieldType =
  | FullName
  | AddressLine1
  | AddressLine2
  | Email
  | Country
  | State
  | City
  | PhoneNumber
  | PostalCode

type fieldValueType = {
  value: string,
  isValid: bool,
}

type formValuesType = {
  fullName: fieldValueType,
  addressLine1: fieldValueType,
  addressLine2: fieldValueType,
  email: fieldValueType,
  country: fieldValueType,
  state: fieldValueType,
  city: fieldValueType,
  phoneNumber: fieldValueType,
  postalCode: fieldValueType,
}
type formValuesValidationType = {
  fullName: string => bool,
  addressLine1: string => bool,
  addressLine2: string => bool,
  email: string => bool,
  country: string => bool,
  state: string => bool,
  city: string => bool,
  phoneNumber: string => bool,
  postalCode: string => bool,
}

let validationRules: formValuesValidationType = {
  fullName: value => value->String.length > 0,
  addressLine1: value => value->String.length > 0,
  addressLine2: value => value->String.length > 0,
  email: value => value->ValidationFunctions.isValidEmail->Option.getOr(false),
  country: value => value->String.length > 0,
  state: value => value->String.length > 0,
  city: value => value->String.length > 0,
  phoneNumber: value => value->String.length > 0,
  postalCode: value => value->String.length > 0,
}
@react.component
let make = () => {
  let initialFormValues: formValuesType = {
    fullName: {value: "", isValid: true},
    addressLine1: {value: "", isValid: true},
    addressLine2: {value: "", isValid: true},
    email: {value: "", isValid: true},
    country: {value: "", isValid: true},
    state: {value: "", isValid: true},
    city: {value: "", isValid: true},
    phoneNumber: {value: "", isValid: true},
    postalCode: {value: "", isValid: true},
  }

  let fieldTypeMap = value =>
    switch value {
    | FullName => "fullName"
    | AddressLine1 => "addressLine1"
    | AddressLine2 => "addressLine2"
    | Email => "email"
    | Country => "country"
    | State => "state"
    | City => "city"
    | PhoneNumber => "phoneNumber"
    | PostalCode => "postalCode"
    }

  let countryArr = ["IN", "US", "AU"]
  let optionalFields = ["city", "addressLine2", "postalCode"]

  let (formValues, setFormValues) = React.useState(() => initialFormValues)

  let isMandatoryField = name => !(optionalFields->Array.includes(fieldTypeMap(name)))
  let numericInput = (inputValue: string) => Js.String.replaceByRe(%re("/\D/g"), "", inputValue)

  let allFields = [
    FullName,
    AddressLine1,
    AddressLine2,
    Email,
    Country,
    State,
    City,
    PhoneNumber,
    PostalCode,
  ]

  let getFieldValue = (fieldName: fieldType) =>
    switch fieldName {
    | FullName => formValues.fullName
    | AddressLine1 => formValues.addressLine1
    | AddressLine2 => formValues.addressLine2
    | Email => formValues.email
    | Country => formValues.country
    | State => formValues.state
    | City => formValues.city
    | PhoneNumber => formValues.phoneNumber
    | PostalCode => formValues.postalCode
    }

  let validateFieldValue = (fieldName, value) =>
    switch fieldName {
    | FullName => validationRules.fullName(value)
    | AddressLine1 => validationRules.addressLine1(value)
    | AddressLine2 => validationRules.addressLine2(value)
    | Email => validationRules.email(value)
    | City => validationRules.city(value)
    | PhoneNumber => validationRules.phoneNumber(value)
    | PostalCode => validationRules.postalCode(value)
    | Country => validationRules.country(value)
    | State => validationRules.state(value)
    }

  let checkAndUpdateField = (fieldName: fieldType, value: string) => {
    let isValid =
      validateFieldValue(fieldName, value) ||
      optionalFields->Array.includes(fieldTypeMap(fieldName))
    setFormValues(prev => {
      switch fieldName {
      | FullName => {...prev, fullName: {value, isValid}}
      | AddressLine1 => {...prev, addressLine1: {value, isValid}}
      | AddressLine2 => {...prev, addressLine2: {value, isValid}}
      | Email => {...prev, email: {value, isValid}}
      | City => {...prev, city: {value, isValid}}
      | PhoneNumber => {...prev, phoneNumber: {value: value->numericInput, isValid}}
      | PostalCode => {...prev, postalCode: {value: value->numericInput, isValid}}
      | Country => {...prev, country: {value, isValid}}
      | State => {...prev, state: {value, isValid}}
      }
    })
  }

  let getCountryData = countryArr => {
    Country.country
    ->Array.filter(item => {
      countryArr->Array.includes(item.isoAlpha2)
    })
    ->Array.map((item): CustomPicker.customPickerType => {
      {
        name: item.countryName,
        value: item.isoAlpha2,
        icon: Utils.getCountryFlags(item.isoAlpha2),
      }
    })
  }

  let countryPickerData = React.useMemo(() => countryArr->getCountryData, [countryArr])

  let handleFormSubmit = e => {
    let allValid = allFields->Array.reduce(true, (acc, fieldName) => {
      let fieldState = getFieldValue(fieldName)
      checkAndUpdateField(fieldName, fieldState.value)
      acc && fieldState.isValid
    })

    if allValid {
      Console.log("Form is valid, proceed with submission")
    } else {
      Console.log("Form has errors")
    }
  }

  let renderInputField = (~heading, ~placeholder, ~fieldType, ~maxLength=?) => {
    let fieldState = getFieldValue(fieldType)
    <CustomInput
      heading={heading}
      placeholder={placeholder}
      height=40.
      fontSize=14.
      maxLength
      animate=false
      mandatory={isMandatoryField(fieldType)}
      state={fieldState.value}
      isValid={fieldState.isValid}
      setState={e => checkAndUpdateField(fieldType, e)}
    />
  }

  let renderPickerInputField = (~heading, ~placeholder, ~fieldType, ~itmes) => {
    let fieldState = getFieldValue(fieldType)
    <CustomPicker
      value=Some(fieldState.value)
      setValue={val => checkAndUpdateField(fieldType, val()->Option.getOr(""))}
      items={itmes}
      placeholderText={placeholder}
      height=40.
      animate=false
      borderBottomLeftRadius=10.
      borderBottomRightRadius=10.
      mandatory={isMandatoryField(fieldType)}
      isValid={fieldState.isValid}
      heading={heading}
    />
  }

  <FullScreenSheetWrapper>
    <Space />
    <View
      style={viewStyle(
        ~flex=1.,
        ~width=100.->pct,
        ~display=#flex,
        ~flexDirection=#column,
        ~justifyContent=#center,
        ~gap=20.,
        (),
      )}>
      {renderInputField(
        ~heading="Full Name",
        ~placeholder="First name and Last name",
        ~fieldType=FullName,
        ~maxLength=30,
      )}
      {renderInputField(
        ~heading="Address Line 1",
        ~placeholder="Street address",
        ~fieldType=AddressLine1,
        ~maxLength=40,
      )}
      {renderInputField(
        ~heading="Address Line 2",
        ~placeholder="Apt., unit number, etc",
        ~fieldType=AddressLine2,
        ~maxLength=40,
      )}
      <View style={viewStyle(~flexDirection=#row, ~gap=15., ~display=#flex, ())}>
        <View style={viewStyle(~flex=1., ())}>
          {renderInputField(~heading="City", ~placeholder="City", ~fieldType=City, ~maxLength=30)}
        </View>
        <View style={viewStyle(~flex=1., ())}>
          {renderPickerInputField(
            ~heading="State",
            ~placeholder="State",
            ~fieldType=State,
            ~itmes=countryPickerData,
          )}
        </View>
      </View>
      <View style={viewStyle(~flexDirection=#row, ~gap=15., ~display=#flex, ())}>
        <View style={viewStyle(~flex=1., ())}>
          {renderPickerInputField(
            ~heading="Country",
            ~placeholder="Country",
            ~fieldType=Country,
            ~itmes=countryPickerData,
          )}
        </View>
        <View style={viewStyle(~flex=1., ())}>
          {renderInputField(
            ~heading="Postal Code",
            ~placeholder="Postal Code",
            ~fieldType=PostalCode,
            ~maxLength=8,
          )}
        </View>
      </View>
      {renderInputField(
        ~heading="Phone Number",
        ~placeholder="000 000 000",
        ~fieldType=PhoneNumber,
        ~maxLength=10,
      )}
      {renderInputField(
        ~heading="Email",
        ~placeholder="Eg:johndoe@gmail.com",
        ~fieldType=Email,
        ~maxLength=50,
      )}
      <Space height=11. />
    </View>
    <CustomButton borderRadius=10. text="Submit" onPress=handleFormSubmit />
  </FullScreenSheetWrapper>
}

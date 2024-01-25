# Hermes

Hermes is a swift package that wraps around apple's native URLSession to organize your APIs.

## Installation

Use the swift package manager (https://github.com/josephjoeljo/Hermes) to add to your project.

## Usage

### Initialization
Hermes uses a class called `Courrier` to help organize your API callS.
```swift
import Hermes

let service = Courrier(.HTTP, host:"your-host")

```

### Use a hostname with port
```swift
import Hermes

let service = Courrier(.HTTP, host:"localhost:80")

```

### Making a GET Request
```swift
// your queries
let queries = [
   URLQueryItem(name: "name", value: "value"),
]

// your endpoint
let endpoint = Endpoint("/path", queries)

// making the request
try {
   let (data, response) = try await service.Request(.GET, endpoint)
} catch (error) {
   // handle error
}
```

### Making a POST Request
```swift

// your endpoint
let endpoint = Endpoint("/path")

// your post data
let data = Data()

// making the request
try {
   let (data, response) = try await service.Request(.POST, endpoint, body: data)
} catch(error) {
   // handle error
}
```

### Using Custom Headers
```swift
let dict = [
   "Connection": "keep-alive"
]

// your endpoint
let endpoint = Endpoint("/path")

// making the request
try {
   let (data, response) = try await service.Request(.POST, endpoint, body: data, headers: dict)
} catch(error) {
   // handle error
}
```

### Error Handling
Force cast down the error thrown as a Network Error
And print the localized Description to see its contents
```swift
let newError = error as! NetworkError
print(newError.localizedDescription)
```

## Contributing

Pull requests are welcome. For major changes, please open an issue first
to discuss what you would like to change.

Please make sure to update tests as appropriate.

## License

[MIT](https://choosealicense.com/licenses/mit

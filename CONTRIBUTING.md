## Contributing

First off, thank you for considering contributing to MetalPetal.

### Pull Requests

If you know exactly how to implement the feature being suggested or fix the bug
being reported, please open a pull request instead of an issue. Pull requests are easier than
patches or inline code blocks for discussing and merging the changes.

If you can't make the change yourself, please open an issue after making sure
that one isn't already logged.

### Contributing Code

Fork this repository, make your change (preferably in a branch named for the
topic), send a pull request.

- Pull requests should contain small, incremental change.

- Code must compile without warnings or static analyzer warnings.

- The committer is responsible for addressing any problems found in the future that the change may cause.

- Follow the `API Design Guidelines`

- Run [`test.sh`](https://github.com/MetalPetal/MetalPetal/blob/master/test.sh) before sending a pull request.

### API Design Guidelines

#### Objective-C

Basically, you should follow Apple's [Objective-C Conventions](https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/Conventions/Conventions.html) as well as [Coding Guidelines for Cocoa](https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/CodingGuidelines/CodingGuidelines.html).

Additionally:

- Use `NS_ENUM` or `NS_OPTIONS` for enumerations. 

- All interfaces should be marked with nullability annotations.

- Always review the generated Swift interfaces, make sure that every single API conforms to the [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/).  Use `NS_SWIFT_NAME` / `NS_SWIFT_UNAVAILABLE` / `NS_REFINED_FOR_SWIFT` whenever needed.

#### Swift

Follow the [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/).

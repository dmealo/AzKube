# Contributing to AzKube

Thank you for your interest in contributing to AzKube! Contributing makes projects so much better and more fun (remember?)! This document provides guidelines and information about contributing to this project.

## Code of Conduct

This project follows our [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## How to Contribute

### Reporting Issues

- Before creating an issue, please check existing issues to avoid duplicates
- Use the issue templates when available
- Provide as much detail as possible:
  - Steps to reproduce
  - Expected behavior
  - Actual behavior
  - PowerShell version
  - Azure CLI version
  - Operating system

### Pull Requests

1. Fork the repository
2. Create a new branch for your changes
3. Make your changes
4. Write or update tests for your changes
5. Run tests locally using Pester
6. Update documentation if needed
7. Submit a pull request

#### Pull Request Guidelines

- Follow the existing code style and conventions
- Include tests for new features
- Update documentation for any changed functionality
- Keep commits focused and atomic
- Use clear commit messages following [conventional commits](https://www.conventionalcommits.org/)
- Reference any related issues using GitHub's keywords

### Development Setup

1. Clone the repository
2. Install required PowerShell modules for running tests:
   ```powershell
   Install-Module -Name Pester -Force -SkipPublisherCheck
   ```
3. Run `.\Local.ps1` to set up local development environment (adds the src/AzKube folder to your PATH for the current PS session)
   1. Add `-Package -Analyze` to test packaging locally before you submit a pull request
   2. Add `-RunAfterBuild` to run `Set-AksClusters` command right away.
4. Run `.\Undo-Local.ps1` to remove any versions of the module for clean slate testing/cleanup. Then run `install-module -Name AzKube` to reinstall from PowerShell Gallery for normal use.

### Running Tests

Run tests using Pester:
- You can run tests in Visual Studio Code using the Pester extension from Pester, and/or use the PowerShell extension from Microsoft for CodeLens runs inline with Tests file(s). If you use both, you should disable Legacy mode for Pester (see Pester and Visual Studio Code documentation on use in VSC).
- You can also run Pester from PowerShell:
```powershell
$config = New-PesterConfiguration
$config.Run.Path = 'tests'
$config.TestResult.Enabled = $true
$config.CodeCoverage.Enabled = $true
Invoke-Pester -Configuration $config
```

## Style Guidelines

- Use standard PowerShell naming conventions
- Follow [PowerShell Best Practices and Style Guide](https://poshcode.gitbook.io/powershell-practice-and-style/)
- Document functions using comment-based help (volunteer to improve existing ones!😁)
- Keep lines under 100 characters where possible
- Use meaningful variable names

## Documentation

- Update README.md for user-facing changes
- Use comment-based help for all public functions
- Keep documentation current with code changes

## Community

- [GitHub Issues](https://github.com/dmealo/AzKube/issues): For bug reports and feature requests
- [GitHub Discussions](https://github.com/dmealo/AzKube/discussions): For general questions and community discussions

## Recognition

Contributors will be automatically recognized in our release notes when PRs are used (so always, right? 😁).

## Questions?

If you have questions about contributing, feel free to:
1. Open a [GitHub Discussion](https://github.com/dmealo/AzKube/discussions)
2. Check existing documentation
3. Review closed issues and pull requests

Thank you for contributing to 🧊AzKube!
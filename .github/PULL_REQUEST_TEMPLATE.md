# Pull Request

## Description
<!-- Provide a brief, clear description of your changes. For automated contributions by coding agents, include the issue reference and approach taken. -->

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Performance improvement
- [ ] Code cleanup/refactoring
- [ ] Test coverage improvement
- [ ] CI/CD enhancement

## Testing
- [ ] All existing tests pass
- [ ] New tests added for new functionality
- [ ] Tests cover error scenarios and edge cases
- [ ] Tests use proper mocking for external dependencies
- [ ] Tested manually in PowerShell (if applicable)
- [ ] No new PSScriptAnalyzer warnings or errors

### Automated Testing Requirements
- [ ] Tests run without external dependencies (Azure CLI, kubectl, network)
- [ ] Mock objects properly configured for Azure services
- [ ] Test coverage maintained or improved
- [ ] Tests follow existing naming conventions

### Tested AKS Versions (if applicable)
<!-- List the AKS versions you've tested with -->
- [ ] Latest GA version
- [ ] Preview version (if applicable)
- [ ] Minimum supported version

## Azure Environment Testing (if applicable)
- [ ] Works with Azure CLI authentication
- [ ] Works with Azure PowerShell authentication
- [ ] Tested with multiple subscriptions
- [ ] Tested with different RBAC configurations

## Code Quality
- [ ] Code follows PowerShell best practices
- [ ] PSScriptAnalyzer passes with no errors
- [ ] Functions have complete comment-based help
- [ ] Error handling includes meaningful messages
- [ ] Code is properly formatted and readable

## Documentation
- [ ] Comment-based help updated for modified functions
- [ ] README.md updated (if user-facing changes)
- [ ] CONTRIBUTING.md updated (if process changes)
- [ ] Examples provided for new functionality

## Module Changes
<!-- List any changes to the module's public interface -->
- New cmdlets:
- Modified cmdlets:
- Removed cmdlets:
- Parameter changes:

## Breaking Changes
<!-- If there are breaking changes, list them here with migration steps -->

## GitHub Copilot Agent Compatibility
For agent-generated contributions:
- [ ] Issue template requirements fully addressed
- [ ] Implementation follows specified acceptance criteria
- [ ] All requested tests and documentation included
- [ ] Code is ready for automated testing in CI/CD

## Related Issues
<!-- Example: Fixes #123, Relates to #456, Implements #789 -->

## Additional Notes
<!-- Any other context about the pull request -->

## Performance Impact
<!-- Describe any performance implications and testing done -->
- [ ] No significant impact
- [ ] Performance improvement
- [ ] Performance regression (justified because...)
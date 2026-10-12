@{
    Severity = @('Error', 'Warning')
    # Focus on correctness and unsafe execution, not stylistic cmdlet boilerplate.
    IncludeRules = @(
        'PSAvoidAssignmentToAutomaticVariable'
        'PSAvoidDefaultValueSwitchParameter'
        'PSAvoidInvokingEmptyMembers'
        'PSAvoidUsingConvertToSecureStringWithPlainText'
        'PSAvoidUsingEmptyCatchBlock'
        'PSAvoidUsingInvokeExpression'
        'PSAvoidUsingPlainTextForPassword'
        'PSAvoidUsingUsernameAndPasswordParams'
        'PSPossibleIncorrectComparisonWithNull'
    )
}

Assert-FnEndpoint -FunctionName "Test" -bindings {
    Assert-FnHttpBinding -In -Methods Get,Post -Route "test/{C}"
}
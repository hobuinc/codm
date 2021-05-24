module.exports.getAccountId = async (context) => {
    return context.providers.aws.getAccountId();
};

package com.clicklogs.Handlers;

import java.util.Arrays;
import com.clicklogs.Authorizer.AuthPolicy;
import com.clicklogs.Authorizer.TokenAuthorizerContext;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;

public class APIGatewayAuthorizerHandler implements RequestHandler<TokenAuthorizerContext, AuthPolicy> {

    @Override
    public AuthPolicy handleRequest(TokenAuthorizerContext input, Context context) {

        System.out.println("Reached lambda authorizer");
        String token = input.getAuthorizationToken();
        System.out.println("received token - " + token);

        String env_auth_tokens = System.getenv("AUTH_TOKENS");
        String[] env_token_split = env_auth_tokens.split(";");

        Boolean is_valid_token = Arrays.asList(env_token_split).contains(token);
    	String principalId = "xxxx";

        if(!is_valid_token){
            throw new RuntimeException("Unauthorized");
        }
        
        String methodArn = input.getMethodArn();
    	String[] arnPartials = methodArn.split(":");
    	String region = arnPartials[3];
    	String awsAccountId = arnPartials[4];
    	String[] apiGatewayArnPartials = arnPartials[5].split("/");
    	String restApiId = apiGatewayArnPartials[0];
    	String stage = apiGatewayArnPartials[1];
        
        System.out.println("methodArn - " + methodArn + "  restApiId - " + restApiId);

        System.out.println("Reached lambda authorizer. Returning allow all policy");
        return new AuthPolicy(principalId, AuthPolicy.PolicyDocument.getAllowAllPolicy(region, awsAccountId, restApiId, stage));
    }

}
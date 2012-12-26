<cfcomponent accessors="true" output="false" hint="userController">

<cfproperty name="framework" />
<cfproperty name="userService" />


<cffunction name="list" returntype="struct" access="public" output="false" hint="Lists the given users">
	<cfargument name="rc" type="struct" required="true" hint="Request-Context" />

	<cfset rc.users = getUserService().load() />

	<cfreturn rc />
</cffunction>

</cfcomponent>
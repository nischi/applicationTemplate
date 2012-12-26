<cfcomponent accessors="true" output="false" hint="userController">

<cfproperty name="framework" />
<cfproperty name="userService" />


<cffunction name="list" returntype="struct" access="public" output="false" hint="Lists the given users">
	<cfargument name="rc" type="struct" required="true" hint="Request-Context" />

	<cfset rc.users = getUserService().load() />

	<cfreturn rc />
</cffunction>


<cffunction name="form" returntype="struct" access="public" output="false" hint="Add a new or edit a given user">
	<cfargument name="rc" type="struct" required="true" hint="Request-Context" />

	<cfset rc.user = getUserService().new(rc) />

	<cfreturn rc />
</cffunction>


<cffunction name="save" returntype="struct" access="public" output="false" hint="Saves a given user">
	<cfargument name="rc" type="struct" required="true" hint="Request-Context" />

	<cfparam name="rc.isActive" type="boolean" default="false" />

	<cfset rc.user = getUserService().new(rc) />
	<cfset getUserService().validate(rc.user) />

	<cfif NOT rc.user.hasError()>
		<cfset getUserService().save(rc.user) />
		<cfset getFramework().redirect('.list') />
	</cfif>

	<cfset getFramework().setView('.form') />

	<cfreturn rc />
</cffunction>

</cfcomponent>
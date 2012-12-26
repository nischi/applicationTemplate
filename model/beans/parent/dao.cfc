<cfcomponent accessors="true" output="false" hint="daoBean">

<cfproperty name="vtResult" />


<cffunction name="hasError" returnType="boolean" access="public" output="false" hint="Checks if there are any validation errors present">
	<cfargument name="property" type="string" required="false" default="" hint="Property to check for errors" />

	<cfreturn NOT isNull(getVTResult()) AND getVTResult().hasErrors(arguments.property)>
</cffunction>


<cffunction name="getErrors" returnType="any" access="public" output="false" hint="Gets the validation errors">
	<cfargument name="property" type="string" required="false" default="" hint="Property to get the errors from" />

	<cfset local.errors = structNew() />

	<cfif hasError(arguments.property)>
		<cfset local.errors = getVTResult().getErrors() />

		<cfif len(arguments.property)>
			<cfset local.errors = local.errors[arguments.property] />
		</cfif>
	</cfif>

	<cfreturn local.errors />
</cffunction>

</cfcomponent>
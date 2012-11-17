<cfcomponent accessors="true" extends="orm" output="false" hint="ormCRUDService">

<cffunction name="load" returntype="any" access="public" output="false" hint="Loads entities - except the deleted ones">
	<cfparam name="arguments[1]" type="struct" default="#structNew()#" />
	<cfset structAppend(arguments[1],{ deletedat=javaCast('null','') }) />

	<cfswitch expression="#structCount(arguments)#">
		<cfcase value="0">
			<cfreturn super.load(local.args) />
		</cfcase>

		<cfcase value="1">
			<cfreturn super.load(arguments[1]) />
		</cfcase>

		<cfcase value="2">
			<cfreturn super.load(arguments[1],arguments[2]) />
		</cfcase>

		<cfcase value="3">
			<cfreturn super.load(arguments[1],arguments[2],arguments[3]) />
		</cfcase>
	</cfswitch>
</cffunction>


<cffunction name="delete" returntype="void" access="public" output="false" hint="Do soft-delete">
	<cfargument name="entity" type="any" required="true" hint="Entity to delete" />

	<cfset arguments.entity.setDeletedAt(now()) />
	<cfset save(arguments.entity) />
</cffunction>


<cffunction name="save" returntype="void" access="public" output="false" hint="Saves a given entity">
	<cfargument name="entity" type="any" required="true" hint="Entity to save" />

	<cfif isNull(arguments.entity.getIdent())>
		<cfset arguments.entity.setIdent(lCase(insert('-',createUUID(),23))) />
	</cfif>

	<cfset super.save(arguments.entity) />
</cffunction>

</cfcomponent>
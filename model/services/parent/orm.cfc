<cfcomponent accessors="true" output="false" hint="baseORMService">

<cffunction name="init" returntype="any" access="public" output="false" hint="Initiates the orm service">
	<cfargument name="entityName" type="string" required="false" default="" hint="Entity name which should be used for ORM actions" />

	<cfif NOT len(arguments.entityName)>
		<cfset arguments.entityName = listLast(getMetaData(this).fullName,'.') />
	</cfif>

	<cfset variables.entityName = arguments.entityName />

	<cfreturn this />
</cffunction>


<cffunction name="delete" returntype="void" access="public" output="false" hint="Deletes a given entity">
	<cfargument name="entity" type="any" required="true" hint="Entity to delete" />

	<cfset entityDelete(arguments.entity) />
</cffunction>


<cffunction name="deleteByPk" returntype="void" access="public" output="false" hint="Deletes an entity with the given primary key">
	<cfargument name="pk" type="any" required="true" hint="Primary key" />

	<cfset local.entity = loadByPk(argumentCollection=arguments) />
	<cfif NOT isNull(local.entity)><cfset delete(local.entity) /></cfif>

</cffunction>


<cffunction name="loadByPk" returntype="any" access="public" output="false" hint="Loads an entity with its primary key">
	<cfargument name="pk" type="any" required="true" hint="Primary key" />

	<cfreturn entityLoad(variables.entityName,{ ident=arguments.pk,deletedAt=javaCast('null','') },true) />
</cffunction>


<cffunction name="load" returntype="any" access="public" output="false" hint="Loads entities with the given parameters">
	<cfswitch expression="#structCount(arguments)#">
		<cfcase value="0">
			<cfreturn entityLoad(variables.entityName) />
		</cfcase>
		<cfcase value="1">
			<cfreturn entityLoad(variables.entityName,arguments[1]) />
		</cfcase>
		<cfcase value="2">
			<cfreturn entityLoad(variables.entityName,arguments[1],arguments[2]) />
		</cfcase>
		<cfcase value="3">
			<cfreturn entityLoad(variables.entityName,arguments[1],arguments[2],arguments[3]) />
		</cfcase>
	</cfswitch>
</cffunction>


<cffunction name="new" returntype="any" access="public" output="false" hint="Gets a new entity instance">
	<cfargument name="properties"	type="struct"		required="false"	default="#structNew()#"	hint="Properties to populate" />
	<cfargument name="context"		type="string"		required="false"	default=""	hint="Context from which keys should be populated" />
	<cfargument name="keys"				type="string"		required="false"	default=""	hint="Keys from properties struct to populate" />
	<cfargument name="trim"				type="boolean"	required="false"	default="false"	hint="If the properties should be trimmed" />

	<cfif structKeyExists(arguments.properties,'ident') AND isValid('guid',arguments.properties.ident)>
		<cfset arguments.entity = loadByPk(arguments.properties.ident) />
	</cfif>

	<cfif isNull(arguments.entity)>
		<cfparam name="arguments.properties.ident" type="string" default="" />
		<cfset arguments.entity = entityNew(variables.entityName,{ ident=arguments.properties.ident }) />
	</cfif>

	<cfif structKeyExists(arguments.properties,'ident')>
		<cfset structDelete(arguments.properties,'ident') />
	</cfif>

	<cfreturn populate(argumentCollection=arguments) />
</cffunction>


<cffunction name="reload" returnType="void" access="public" output="false" hint="Reloads a given entity">
	<cfargument name="entity" type="any" required="true" hint="Entity to reload" />

	<cfset entityReload(arguments.entity) />
</cffunction>


<cffunction name="save" returntype="void" access="public" output="false" hint="Saves a given entity">
	<cfargument name="entity" type="any" required="true" hint="Entity to save" />

	<cfset entitySave(arguments.entity) />
</cffunction>


<cffunction name="populate" returntype="any" access="public" output="false" hint="Populates a given entity">
	<cfargument name="entity"			type="any"			required="true" 	hint="Entity to populate" />
	<cfargument name="properties"	type="struct"		required="true"		hint="Properties to populate" />
	<cfargument name="context"		type="string"		required="false"	default=""	hint="Context from which keys should be populated" />
	<cfargument name="keys"				type="string"		required="false"	default=""	hint="Keys from properties struct to populate" />
	<cfargument name="trim"				type="boolean"	required="false"	default="false"	hint="If the properties should be trimmed" />

	<cfif NOT len(arguments.keys)>
		<cfset arguments.keys = structKeyList(arguments.properties) />
	</cfif>

	<cfloop from="1" to="#listLen(arguments.keys)#" index="local.i">
		<cfset local.property	= listGetAt(arguments.keys,local.i) />
		<cfset local.context	= '' />

		<cfif listLen(local.property,'_') EQ 2>
			<cfset local.context	= listFirst(local.property,'_') />
			<cfset local.property	= listLast(local.property,'_') />
		</cfif>

		<cfif arguments.context EQ local.context AND structKeyExists(arguments.entity,'set#local.property#')>
			<cfset local.maySet = false />

			<cfif len(local.context) AND isDefined('arguments.properties.#local.context#_#local.property#') OR isDefined('arguments.properties.#local.property#')>
				<cfif len(local.context)>
					<cfset local.propertyValue = arguments.properties['#local.context#_#local.property#'] />
				<cfelse>
					<cfset local.propertyValue = arguments.properties[local.property] />
				</cfif>

				<cfif arguments.trim AND isSimpleValue(local.propertyValue)>
					<cfset local.propertyValue = trim(local.propertyValue) />
				</cfif>

				<cfinvoke component="#arguments.entity#" method="set#local.property#">
					<cfinvokeargument name="#local.property#" value="#local.propertyValue#" />
				</cfinvoke>
			</cfif>
		</cfif>
	</cfloop>

	<cfreturn arguments.entity />
</cffunction>


<cffunction name="toPk" returntype="any" access="public" output="false" hint="Returns the primary key of a given object or an array of primary keys">
	<cfargument name="entities" type="any" required="true" hint="Entities to get the primary keys from" />

	<cfif isArray(arguments.entities)>
		<cfset local.result = arrayNew(1) />

		<cfloop array="#arguments.entities#" index="local.entity">
			<cfset arrayAppend(local.result,local.entity.getIdent()) />
		</cfloop>
	<cfelse>
		<cfset local.result = arguments.entities.getIdent() />
	</cfif>

	<cfreturn local.result />
</cffunction>

</cfcomponent>
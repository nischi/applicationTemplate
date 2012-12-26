<cfcomponent accessors="true" extends="dao" mappedSuperClass="true" output="false" hint="crudBean">

<cfproperty name="ident"	ormType="string"	notNull="true"	length="36"	fieldType="id"	hint="Unique primary key" />

<cfproperty name="isactive"		ormType="boolean"		notNull="true"	default="true"	dbDefault="1"	hint="If the current entity is active" />
<cfproperty name="createdat"	ormType="timestamp"	notNull="true"	hint="Time of creation" />
<cfproperty name="updatedat"	ormType="timestamp"	hint="Time of last update" />
<cfproperty name="deletedat"	ormType="timestamp"	hint="Time of deletion" />


<cffunction name="preInsert" returntype="void" access="public" output="false" hint="Executes before the entity insert">
	<cfif isNull(variables.createdAt)><cfset variables.createdAt = now() /></cfif>
</cffunction>


<cffunction name="preUpdate" returntype="void" access="public" output="false" hint="Executes before the update of the entity">
	<cfargument name="oldData" type="struct" required="true" hint="Data before entity update" />

	<cfif isNull(variables.deletedAt)><cfset variables.updatedAt = now() /></cfif>
</cffunction>


<cffunction name="setIdent" returntype="void" access="public" output="false" hint="Setter of the ident property">
	<cfargument name="ident" type="string" required="true" hint="ident" />

	<cfif isValid('guid',arguments.ident)><cfset variables.ident = arguments.ident /></cfif>
</cffunction>

</cfcomponent>
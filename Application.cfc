<cfcomponent output="false" extends="libs.framework">

<cfset this.mappings['/model']					= '#getDirectoryFromPath(getCurrentTemplatePath())#model' />
<cfset this.mappings['/cfformprotect']	= '#getDirectoryFromPath(getCurrentTemplatePath())#libs/cfformprotect' />
<cfset this.mappings['/validateThis']		= '#getDirectoryFromPath(getCurrentTemplatePath())#libs/validateThis' />
<cfset this.mappings['/mxunit']					= '#getDirectoryFromPath(getCurrentTemplatePath())#libs/mxunit' />

<cfset structAppend(this,applicationConfig()) />
<cfset variables.framework = frameworkConfig() />


<cffunction name="applicationConfig" returnType="struct" access="public" output="false" hint="Application configuration">
	<cfset local.application	= { ormEnabled=false } />
	<cfset local.datasource		= getSystemString('application.datasource') />

	<cfif len(local.datasource)>
		<cfset local.application.datasource		= local.datasource />
		<cfset local.application.ormEnabled		= true />
		<cfset local.application.ormSettings	= {
			dbCreate=getSystemString('application.dbCreate'),
			cfcLocation=['model/beans'],
			eventHandling=true
		} />
	</cfif>

	<cfreturn local.application />
</cffunction>


<cffunction name="frameworkConfig" returnType="struct" access="public" output="false" hint="FW/1 configuration">
	<cfset local.framework = {
		usingSubsystems=true,
		defaultSubsystem='public'
	} />

	<cfloop list="generateSES,reloadApplicationOnEveryRequest" index="local.key">
		<cfset local.framework['#local.key#'] = yesNoFormat(getSystemString('framework.#local.key#')) />
	</cfloop>

	<cfreturn local.framework />
</cffunction>


<cffunction name="setupApplication" returnType="void" access="public" output="false">
	<cfif this.ormEnabled><cfset ormReload() /></cfif>
	<cflock type="exclusive" timeout="50">
		<cfset local.beanFactory = new libs.ioc('model/services',{ exclude=['parent'] }) />

		<cfset local.beanFactory.addBean('framework',this) />
		<cfset local.beanFactory.addBean('i18n',new libs.i18n('model/languages')) />

		<cfset setBeanFactory(local.beanFactory) />
	</cflock>
</cffunction>


<cffunction name="setupSubsystem" returntype="void" access="public" output="false">
	<cfargument name="subsystem"	type="string"	required="true" />
	<cfset local.beanFactory = new libs.ioc(arguments.subsystem) />

	<cfset local.beanFactory.setParent(getDefaultBeanFactory()) />
	<cfset local.beanFactory.addBean('i18n',new libs.i18n('#arguments.subsystem#/languages',{ parent=getDefaultBeanFactory().getBean('i18n') })) />

	<cfset setSubsystemBeanFactory(arguments.subsystem,local.beanFactory) />
</cffunction>


<cffunction name="translate" returntype="string" access="public" output="false" hint="Translates a given key into a given locale">
	<cfargument name="key"			type="string"	required="true"		hint="Key to get value from" />
	<cfargument name="format"		type="string"	required="false"	default="plain"	hint="To which format the key should be transformed: plain, html, js, xml" />
	<cfargument name="args"			type="any"		required="false"	default=""	hint="Arguments for variables in translation. May be a list or array" />
	<cfargument name="locale"		type="string"	required="false"	default="#getLocale()#"	hint="Locale to get the value from" />
	<cfargument name="baseName"	type="string"	required="false"	default=""	hint="Base name to get the value from" />

	<cfset local.key = getBeanFactory().getBean('i18n').formatKey(argumentCollection=arguments) />

	<cfswitch expression="#lCase(arguments.format)#">
		<cfcase value="html"><cfset local.key = htmlEditFormat(local.key) /></cfcase>
		<cfcase value="js,javascript"><cfset local.key = jsStringFormat(local.key) /></cfcase>
		<cfcase value="xml"><cfset local.key = xmlFormat(local.key) /></cfcase>
	</cfswitch>

	<cfreturn local.key />
</cffunction>


<cffunction name="getSystemString" returntype="any" access="private" output="false" hint="Gets a system configuration value">
	<cfargument name="key" type="string" required="true" hint="Configuration key" />

	<cfreturn getProfileString('#this.mappings['/model']#/configs/system.ini',listFirst(arguments.key,'.'),listLast(arguments.key,'.'))>
</cffunction>

</cfcomponent>
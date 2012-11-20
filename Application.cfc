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
		generateSES=true,
		defaultSubsystem='public'
	} />
	<cfset local.framework.reloadApplicationOnEveryRequest = yesNoFormat(getSystemString('framework.reloadApplicationOnEveryRequest')) />

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


<cffunction name="getSystemString" returntype="any" access="private" output="false" hint="Gets a system configuration value">
	<cfargument name="key" type="string" required="true" hint="Configuration key" />

	<cfreturn getProfileString('#this.mappings['/model']#/configs/system.ini',listFirst(arguments.key,'.'),listLast(arguments.key,'.'))>
</cffunction>

</cfcomponent>

<!---
<cfset this.applicationRoot	= replace(getDirectoryFromPath(getCurrentTemplatePath()),'\','/','all') />
<cfset this.requestRoot			= replace(getDirectoryFromPath(getBaseTemplatePath()),'\','/','all') />

<cfset this.mappings['/model']					= '#this.applicationRoot#model' />
<cfset this.mappings['/cfformprotect']	= '#this.applicationRoot#model/libs/cfformprotect' />
<cfset this.sessionManagement	= true />

<cfset structAppend(this,system()) />
<cfset variables.framework = framework() />


<cffunction name="system" returntype="struct" access="private" output="false" hint="Loads the system configuration">

	<cfset local.system			= { ormEnabled=false, isInstalled=yesNoFormat(getIniString('system:application.isInstalled')) } />
	<cfset local.datasource	= getIniString('system:application.datasource') />

	<cfif len(local.datasource)>
		<cfset local.system.datasource	= local.datasource />
		<cfset local.system.ormEnabled	= true />
		<cfset local.system.ormSettings	= {
			dbCreate=getIniString('system:application.dbCreate'),
			cfcLocation=['model/beans'],
			eventHandling=true
		} />
	</cfif>

	<cfreturn local.system />
</cffunction>


<cffunction name="framework" returntype="struct" access="private" output="false" hint="Loads the framework configuration">

	<cfset local.framework	= {
		usingSubsystems=true,
		generateSES=true,
		defaultSubsystem='blog',
		home='blog:entry.search',
		routes = [
			{ '/admin'='/admin:entry/list',hint='/admin shortcut' },{
				'/entry/show/:year/:month/:day/:sestitle'='/entry/search/year/:year/month/:month/day/:day/sestitle/:sestitle',
				'/entry/show/:year/:month/:day'='/entry/search/year/:year/month/:month/day/:day',
				'/entry/show/:year/:month'='/entry/search/year/:year/month/:month',
				'/entry/show/:year'='/entry/search/year/:year',
				'/entry/category/:category'='/entry/search/categories/:category',
				'/entry/search/:query'='/entry/search/query/:query',
				'/entry/list'='/entry/search',
				hint='Different entry ses url strings'
			}]
	} />

	<cfset local.framework.reloadApplicationOnEveryRequest = yesNoFormat(getIniString('system:application.reloadOnEveryRequest')) />

	<cfreturn local.framework />
</cffunction>


<cffunction name="setupApplication" returntype="void" access="public" output="false">
	<cfset ormReload() />
	<cfif this.applicationRoot NEQ this.requestRoot><cfset resolveSubsystemDirectLink() /></cfif>
	<cfset setBeanFactory(new model.libs.ioc('model/services')) />
	<cfset getDefaultBeanFactory().addBean('framework',this) />
	<cfset getDefaultBeanFactory().addBean('validator',new model.libs.validator({ locale=getBeanFactory().getBean('languageService').getJavaLocale(),path='#this.mappings['/model']#/languages' })) />
	<cfset getDefaultBeanFactory().addBean('cffp',new model.libs.cffp()) />
</cffunction>


<cffunction name="setupSubsystem" returntype="void" access="public" output="false">
	<cfargument name="subsystem" type="string" required="true" hint="Name of the subsystem to start" />

	<cfif this.applicationRoot NEQ this.requestRoot><cfset resolveSubsystemDirectLink() /></cfif>

	<cfif directoryExists('#getDirectoryFromPath(getCurrentTemplatePath())##arguments.subsystem#/controllers')>
		<cfset local.beanFactory = new model.libs.ioc('#arguments.subsystem#/controllers') />
		<cfset local.beanFactory.setParent(getDefaultBeanFactory()) />

		<cfset setSubsystemBeanFactory(arguments.subsystem,local.beanFactory) />
	</cfif>

	<cfif directoryExists('#getDirectoryFromPath(getCurrentTemplatePath())##arguments.subsystem#/languages')>
		<cfset getBeanFactory().getBean('languageService').addResourceBundlesFromPath('#getDirectoryFromPath(getCurrentTemplatePath())##arguments.subsystem#/languages') />
	</cfif>

	<cfif hasSkin(argumentCollection=arguments)>
		<cfset loadSkinLanguages(getSkin(argumentCollection=arguments),arguments.subsystem) />
	</cfif>
</cffunction>


<cffunction name="setupRequest" returntype="void" access="public" output="false">
	<cfif this.applicationRoot NEQ this.requestRoot><cfset resolveSubsystemDirectLink() /></cfif>
	<cfif NOT this.isInstalled AND getSubsystem() NEQ 'install'><cfset redirect('install:main.default') /></cfif>

	<cfif findNoCase('mobile',cgi.http_user_agent) AND NOT hasSkin()><cfset setSkin('mobile') /></cfif>
	<cfif structKeyExists(request.context,'skin')><cfset setSkin(request.context.skin) /></cfif>
	<cfif len(getIniString('skin:language.system'))><cfset setLocale(getIniString('skin:language.system')) /></cfif>

	<cfswitch expression="#getSubsystem()#">
		<cfcase value="install">
			<cfif this.isInstalled><cfset redirect(variables.framework.home) /></cfif>
		</cfcase>

		<cfcase value="blog">
			<cfset local.pods = getIniString('skin:layout.pods') />
			<cfset request.context.skinGoogleAnalyticsKey = getIniString('skin:googleAnalytics.key') />

			<cfif listFindNoCase(local.pods,'categories')>
				<cfset request.context.pods.categories = getBeanFactory().getBean('categoryService').loadUsed({},'board ASC') />
			</cfif>
			<cfif listFindNoCase(local.pods,'lastComments')>
				<cfset request.context.pods.lastComments = getBeanFactory().getBean('commentService').load({},'createdat DESC',{ maxResults=getIniString('pod:lastComments.maxResults') }) />
			</cfif>
			<cfif listFindNoCase(local.pods,'pages')>
				<cfset request.context.pods.pages = listToArray(getIniString('skin:layout.pages')) />
			</cfif>
		</cfcase>

		<cfcase value="admin">
			<cfif NOT getBeanFactory().getBean('securityService').isUserLoggedIn() AND getItem() NEQ 'login'>
				<cfset redirect('user.login') />
			</cfif>

			<cfif getFullyQualifiedAction() EQ getFullyQualifiedAction('entry.search')>
				<cfset request.context.pods.navbar.entryCount = getBeanFactory().getBean('entryService').count(argumentCollection=request.context) />
			<cfelse>
				<cfset request.context.pods.navbar.entryCount = getBeanFactory().getBean('entryService').count() />
			</cfif>

			<cfset request.context.pods.navbar.categoryCount	= getBeanFactory().getBean('categoryService').count() />
			<cfset request.context.pods.navbar.commentCount		= getBeanFactory().getBean('commentService').count() />
			<cfset request.context.pods.navbar.userCount			= getBeanFactory().getBean('userService').count() />
		</cfcase>

		<cfcase value="dash">
			<cfif NOT getBeanFactory().getBean('securityService').isUserLoggedIn() AND getItem() NEQ 'login'>
				<cfset redirect('user.login') />
			</cfif>
		</cfcase>
	</cfswitch>

</cffunction>


<cffunction name="customizeViewOrLayoutPath" returntype="string" access="public" output="false">
	<cfargument name="pathInfo"	type="struct"	required="true"	hint="Pfad Informationen" />
	<cfargument name="type"			type="string"	required="true"	hint="Typ" />
	<cfargument name="fullPath"	type="string"	required="true"	hint="Voller Pfad" />

	<cfset local.path = '#arguments.pathInfo.base##arguments.type#s/#arguments.pathInfo.path#.cfm' />

	<cfif this.applicationRoot EQ this.requestRoot>
		<cfif isDefined('session.#getSubsystem()#.skin')>
			<cfset local.skin	= session[getSubsystem()]['skin'] />
		<cfelse>
			<cfset local.skin = getIniString('subsystem:#getSubsystem()#.skin') />
		</cfif>

		<cfif len(local.skin)>
			<cfset local.skinPath = '#arguments.pathInfo.base#skins/#local.skin#/#arguments.type#s/#arguments.pathInfo.path#.cfm' />

			<cfif fileExists(expandPath(local.skinPath))>
				<cfset local.path = local.skinPath />
			</cfif>
		</cfif>
	</cfif>

	<cfreturn local.path />
</cffunction>


<cffunction name="translate" returntype="string" access="public" output="false" hint="Translates a given key">
	<cfargument name="key"		type="string"	required="true"		hint="Key which should be translated" />
	<cfargument name="groups"	type="string"	required="false"	default="#getSkin()#"	hint="Resource bundle group which should be used" />

	<cfreturn getBeanFactory().getBean('languageService').translate(argumentCollection=arguments) />
</cffunction>


<cffunction name="getJavaLocale" returntype="string" access="public" output="false" hint="Returns the current java locale">
	<cfreturn getBeanFactory().getBean('languageService').getJavaLocale(argumentCollection=arguments) />
</cffunction>


<cffunction name="resolveSubsystemDirectLink" returntype="void" access="private" output="false" hint="Redirects directly to a subsystem if requested in url">
	<cflocation url="#buildURL('#listLast(this.requestRoot,'/')#:','#right(this.applicationRoot,len(this.applicationRoot) - len(expandPath('/')) + 1)#index.cfm')#" addToken="false" />
</cffunction>


<cffunction name="getIniString" returntype="any" access="public" output="false" hint="Gets a configuration value from a given *.ini file">
	<cfargument name="key"				type="string"	required="true"		hint="Configuration key" />
	<cfargument name="subsystem"	type="string"	required="false"	default=""	hint="Subsystem" />

	<cfif NOT len(arguments.subsystem) AND structKeyExists(request,'action')>
		<cfset arguments.subsystem = getSubsystem() />
	</cfif>

	<cfif NOT hasSkin() AND len(arguments.subsystem)><cfset setSkin(getProfileString('#this.applicationRoot#configs/subsystem.ini',arguments.subsystem,'skin')) /></cfif>

	<cfset local.file			= listFirst(arguments.key,':') />
	<cfset local.section	= listFirst(listLast(arguments.key,':'),'.') />
	<cfset local.item			= listLast(arguments.key,'.') />

	<cfif len(arguments.subsystem) AND fileExists('#this.applicationRoot##arguments.subsystem#/skins/#session[arguments.subsystem]['skin']#/configs/#local.file#.ini')>
		<cfset local.value = getProfileString('#this.applicationRoot##arguments.subsystem#/skins/#session[arguments.subsystem]['skin']#/configs/#local.file#.ini',local.section,local.item) />

	<cfelseif len(arguments.subsystem) AND fileExists('#this.applicationRoot##arguments.subsystem#/configs/#local.file#.ini')>
		<cfset local.value = getProfileString('#this.applicationRoot##arguments.subsystem#/configs/#local.file#.ini',local.section,local.item) />

	<cfelseif fileExists('#this.applicationRoot#configs/#local.file#.ini')>
		<cfset local.value = getProfileString('#this.applicationRoot#configs/#local.file#.ini',local.section,local.item)>
	<cfelse>
		<cfset local.value = '' />
	</cfif>

	<cfreturn local.value />
</cffunction>


<cffunction name="setIniString" returntype="any" access="public" output="false" hint="Sets a configuration value to a given *.ini file">
	<cfargument name="key"				type="string"		required="true"		hint="Configuration key" />
	<cfargument name="value"			type="string"		required="true"		hint="Value to set" />
	<cfargument name="subsystem"	type="string"		required="false"	default=""	hint="Subsystem" />
	<cfargument name="skin"				type="string"		required="false"	default=""	hint="Skin" />
	<cfargument name="force"			type="boolean"	required="false"	default="false"	hint="If value should be written regardless if the file exists or not" />

	<cfset local.path			= '' />
	<cfset local.file			= listFirst(arguments.key,':') />
	<cfset local.section	= listFirst(listLast(arguments.key,':'),'.') />
	<cfset local.item			= listLast(arguments.key,'.') />

	<cfif len(arguments.subsystem) AND len(arguments.skin) AND (arguments.force OR fileExists('#this.applicationRoot##arguments.subsystem#/skins/#session[arguments.subsystem]['skin']#/configs/#local.file#.ini'))>
		<cfset local.path = '#this.applicationRoot##arguments.subsystem#/skins/#session[arguments.subsystem]['skin']#/configs/#local.file#.ini' />

	<cfelseif len(arguments.subsystem) AND (arguments.force OR fileExists('#this.applicationRoot##arguments.subsystem#/configs/#local.file#.ini'))>
		<cfset local.path = '#this.applicationRoot##arguments.subsystem#/configs/#local.file#.ini' />

	<cfelseif arguments.force OR fileExists('#this.applicationRoot#configs/#local.file#.ini')>
		<cfset local.path = '#this.applicationRoot#configs/#local.file#.ini' />
	</cfif>

	<cfif len(local.path)><cfset setProfileString(local.path,local.section,local.item,arguments.value) /></cfif>
</cffunction>


<cffunction name="setSkin" returntype="void" access="private" output="false" hint="Sets a skin">
	<cfargument name="skin"				type="string"	required="true"		hint="Skin to look for" />
	<cfargument name="subsystem"	type="string"	required="false"	default=""	hint="Subsystem to check for a skin" />

	<cfif NOT len(arguments.subsystem) AND structKeyExists(request,'action')>
		<cfset arguments.subsystem = getSubsystem() />
	</cfif>

	<cfif len(arguments.subsystem)>
		<cfset loadSkinLanguages(argumentCollection=arguments) />
		<cfset session[arguments.subsystem]['skin'] = arguments.skin />
	</cfif>
</cffunction>


<cffunction name="hasSkin" returntype="boolean" access="private" output="false" hint="Check whether there is a skin set or not">
	<cfargument name="skin"				type="string"	required="false"	default=""	hint="Skin to look for" />
	<cfargument name="subsystem"	type="string"	required="false"	default=""	hint="Subsystem to check for a skin" />

	<cfif NOT len(arguments.subsystem) AND structKeyExists(request,'action')>
		<cfset arguments.subsystem = getSubsystem() />
	</cfif>

	<cfreturn len(arguments.subsystem) AND isDefined('session.#arguments.subsystem#.skin') AND len(session[arguments.subsystem]['skin']) AND (NOT len(arguments.skin) OR session[arguments.subsystem]['skin'] EQ arguments.skin) />
</cffunction>


<cffunction name="getSkin" returntype="string" access="private" output="false" hint="Gets the currently used skin for a subsystem">
	<cfargument name="subsystem" type="string" required="false" default="" hint="Subsystem from which to return the skin" />

	<cfset local.skin = '' />

	<cfif NOT len(arguments.subsystem) AND structKeyExists(request,'action')>
		<cfset arguments.subsystem = getSubsystem() />
	</cfif>

	<cfif hasSkin(argumentCollection=arguments)>
		<cfset local.skin = session[arguments.subsystem]['skin'] />
	</cfif>

	<cfreturn local.skin />
</cffunction>


<cffunction name="loadSkinLanguages" returntype="void" access="private" output="false" hint="Loads the skin languages">
	<cfargument name="skin"				type="string"	required="true"		hint="Skin to look for" />
	<cfargument name="subsystem"	type="string"	required="false"	default=""	hint="Subsystem to check for a skin" />

	<cfif NOT len(arguments.subsystem) AND structKeyExists(request,'action')>
		<cfset arguments.subsystem = getSubsystem() />
	</cfif>

	<cfset local.skinLanguages = '#this.applicationRoot##arguments.subsystem#/skins/#arguments.skin#/languages' />

	<cfif directoryExists(local.skinLanguages)>
		<cfset local.languageService = getBeanFactory().getBean('languageService') />

		<cfif NOT local.languageService.hasResourceBundles(group=arguments.skin)>
			<cfset local.languageService.addResourceBundlesFromPath(local.skinLanguages,arguments.skin) />
		</cfif>
	</cfif>
</cffunction>


<cffunction name="buildApiURL" returntype="string" access="public" output="false" hint="Builds the API URL">
	<cfargument name="action" type="string" required="true" hint="Action to build the URL for" />

	<cfreturn '#request.base#model/index.cfm/#arguments.action#' />
</cffunction>


<cffunction name="getAssetsURL" returntype="string" access="public" output="false" hint="Gets the global assets URL">
	<cfreturn '#lCase(listFirst(cgi.server_protocol,'/'))#://#cgi.http_host##request.base#assets/' />
</cffunction>


<cffunction name="getSkinAssetsURL" returntype="string" access="public" output="false" hint="Gets the skin assets URL">
	<cfargument name="skin" type="string" required="true" hint="Skin of which the assets URL should be returned" />

	<cfset local.url = '#lCase(listFirst(cgi.server_protocol,'/'))#://#cgi.http_host##request.base##getSubsystem()#/' />
	<cfif arguments.skin NEQ 'default'>
		<cfset local.url = '#local.url#skins/#arguments.skin#/' />
	</cfif>
	<cfset local.url = '#local.url#assets/' />

	<cfreturn local.url />
</cffunction>

</cfcomponent>--->

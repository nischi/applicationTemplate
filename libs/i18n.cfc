<cfcomponent output="false" hint="i18n">

<cffunction name="init" returnType="any" access="public" output="false" hint="Constructor">
	<cfargument name="basePath" type="string" required="false"	default="" hint="Base path to load resource bundles from" />
	<cfargument name="config"		type="struct"	required="false"	default="#structNew()#"	hint="Configuration structure" />

	<cfset variables.resourceBundles = structNew() />

	<cfif structKeyExists(arguments.config,'parent')>
		<cfset variables.parent = arguments.config.parent />
	</cfif>

	<cfif len(arguments.basePath)>
		<cfset loadResourceBundles(arguments.basePath) />
	</cfif>

	<cfreturn this />
</cffunction>


<cffunction name="containsKey" returnType="boolean" access="public" output="false" hint="Checks if the resource bundle contains a given key">
	<cfargument name="key"			type="string"	required="true"		hint="Key to get value from" />
	<cfargument name="locale"		type="string"	required="false"	default="#getLocale()#"	hint="Locale to get the value from" />
	<cfargument name="baseName"	type="string"	required="false"	default=""	hint="Base name to get the value from" />

	<cfset arguments.missing = '' />

	<cfreturn yesNoFormat(len(getKey(argumentCollection=arguments))) />
</cffunction>


<cffunction name="getKey" returnType="string" access="public" output="false" hint="Gets a given key">
	<cfargument name="key"			type="string"	required="true"		hint="Key to get value from" />
	<cfargument name="locale"		type="string"	required="false"	default="#getLocale()#"	hint="Locale to get the value from" />
	<cfargument name="baseName"	type="string"	required="false"	default=""	hint="Base name to get the value from" />
	<cfargument name="missing"	type="string"	required="false"	default="#arguments.key#"	hint="Value to use if the key is missing" />

	<cfset local.keyString	= '' />
	<cfset local.bundleName	= getJavaLocale(arguments.locale) />

	<cfif len(arguments.baseName)>
		<cfset local.bundleName = listPrepend(local.bundleName,arguments.baseName,'_') />
	</cfif>

	<cfloop condition="len(local.bundleName)">
		<cfif structKeyExists(variables.resourceBundles,local.bundleName) AND structKeyExists(variables.resourceBundles[local.bundleName],arguments.key)>
			<cfset local.keyString = variables.resourceBundles[local.bundleName][arguments.key] />
			<cfbreak />
		</cfif>

		<cfset local.bundleName = listDeleteAt(local.bundleName,listLen(local.bundleName,'_'),'_') />
	</cfloop>

	<cfif NOT len(local.keyString)>
		<cfset local.keyString = arguments.missing />

		<cfif structKeyExists(variables,'parent') AND variables.parent.containsKey(argumentCollection=arguments)>
			<cfset local.keyString = variables.parent.getKey(argumentCollection=arguments) />
		</cfif>
	</cfif>

	<cfreturn local.keyString />
</cffunction>


<cffunction name="formatKey" returnType="string" access="public" output="false" hint="Formats a given key">
	<cfargument name="key"			type="string"	required="true"		hint="Key to get value from" />
	<cfargument name="locale"		type="string"	required="false"	default="#getLocale()#"	hint="Locale to get the value from" />
	<cfargument name="baseName"	type="string"	required="false"	default=""	hint="Base name to get the value from" />
	<cfargument name="args"			type="any"		required="false"	default=""	hint="Arguments for variables in message. May be a list or array" />

	<cfset arguments.pattern = getKey(argumentCollection=arguments) />
	<cfreturn formatPattern(argumentCollection=arguments) />
</cffunction>


<cffunction name="formatPattern" returntype="string" access="public" output="false" hint="Formats a given pattern">
	<cfargument name="pattern"	type="string"	required="true"		hint="Message to use for formatting" />
	<cfargument name="locale"		type="string"	required="false"	default="#getLocale()#"	hint="Locale to use for formatting" />
	<cfargument name="args"			type="any"		required="false"	default=""	hint="Arguments for variables in message. May be a list or array" />

	<cfset local.javaLocale = getJavaLocale(arguments.locale) />
	<cfif isSimpleValue(arguments.args)>
		<cfset arguments.args = listToArray(arguments.args) />
	</cfif>

	<cfset local.regex					= '(\{[0-9]{1,},number.*?\})' />
	<cfset local.regexPattern		= createObject('java','java.util.regex.Pattern') />
	<cfset local.formatLocale		= createObject('java','java.util.Locale').init(listFirst(local.javaLocale,'_'),listLast(local.javaLocale,'_')) />
	<cfset local.messageFormat	= createObject('java','java.text.MessageFormat').init(arguments.pattern,local.formatLocale) />
	<cfset local.regexCompiled	= local.regexPattern.compile(local.regex,local.regexPattern.CASE_INSENSITIVE) />
	<cfset local.regexMatcher		= local.regexCompiled.matcher(arguments.pattern) />

	<cfloop condition="local.regexMatcher.find()">
		<cfset local.i = listFirst(replace(local.regexMatcher.group(),'{','')) />
		<cfset arguments.args[local.i] = javaCast('float',arguments.args[local.i]) />
	</cfloop>
	<cfset arrayPrepend(arguments.args,'') />

	<cfreturn local.messageFormat.format(arguments.args.toArray()) />
</cffunction>


<cffunction name="loadResourceBundles" returnType="void" access="public" output="false" hint="Loads the given resource bundle">
	<cfargument name="basePath" type="string" required="true" hint="Base path to load resource bundles from" />

	<cfset local.baseDirectory = '' />

	<cfif NOT directoryExists(arguments.basePath) AND NOT fileExists(arguments.basePath)>
		<cfset arguments.basePath = expandPath(arguments.basePath) />
	</cfif>

	<cfif fileExists(arguments.basePath)>
		<cfset local.baseDirectory = getDirectoryFromPath(arguments.basePath) />

	<cfelseif directoryExists(arguments.basePath)>
		<cfset local.baseDirectory = arguments.basePath />
	</cfif>

	<cfif len(local.baseDirectory)>
		<cfset local.resourceBundlePaths = directoryList(local.baseDirectory,false,'path','*.properties') />

		<cfloop array="#local.resourceBundlePaths#" index="local.resourceBundlePath">
			<cfset loadResourceBundle(local.resourceBundlePath) />
		</cfloop>
	</cfif>
</cffunction>


<cffunction name="loadResourceBundle" returnType="void" access="public" output="false" hint="Loads a given resource bundle">
	<cfargument name="bundlePath" type="string" required="true" hint="Path to load resource bundle from" />

	<cfif NOT fileExists(arguments.bundlePath)>
		<cfset arguments.bundlePath = expandPath(arguments.bundlePath) />
	</cfif>

	<cfif fileExists(arguments.bundlePath)>
		<cfset local.fileName						= getFileFromPath(arguments.bundlePath) />
		<cfset local.resourceBundleName	= listDeleteAt(local.fileName,listLen(local.fileName,'.'),'.') />
		<cfset local.fileInputStream		= createObject('java','java.io.FileInputStream').init(arguments.bundlePath) />
		<cfset local.resourceBundle			= createObject('java','java.util.PropertyResourceBundle').init(local.fileInputStream) />

		<cfset local.keys = local.resourceBundle.getKeys() />
		<cfloop condition="#local.keys.hasMoreElements()#">
			<cfset local.key = local.keys.nextElement() />
			<cfset variables.resourceBundles['#local.resourceBundleName#']['#local.key#'] = local.resourceBundle.getString(local.key) />
		</cfloop>

		<cfset local.fileInputStream.close() />
	</cfif>
</cffunction>


<cffunction name="setParent" returnType="void" access="public" output="false" hint="Sets the parent resource bundle">
	<cfargument name="parent" type="any" required="true" hint="Parent resource bundle manager" />

	<cfset variables.parent = arguments.parent />
</cffunction>


<cffunction name="getJavaLocale" returnType="string" access="public" output="false" hint="Gets the current java locale">
	<cfargument name="locale" type="string" required="false" default="#getLocale()#" hint="Locale to get the Java locale from" />

	<cfset local.javaLocale = '' />

	<cfif findNoCase('Railo',server.coldfusion.productName)>
		<cfset local.javaLocale = railoJavaLocale(arguments.locale) />
	<cfelse>
		<cfset local.javaLocale = adobeJavaLocale(arguments.locale) />
	</cfif>

	<cfreturn local.javaLocale />
</cffunction>


<cffunction name="adobeJavaLocale" returnType="string" access="private" output="false" hint="Gets the java locale for Adobe ColdFusion">
	<cfargument name="locale" type="string" required="false" default="#getLocale()#" hint="Locale to get the Java locale from" />

	<cfset local.javaLocale				= '' />
	<cfset local.preservedLocale	= getLocale() />

	<cfset setLocale(arguments.locale) />

	<cfset local.runtimeLocale = getPageContext().getResponse().getLocale() />
	<cfif isNull(local.locale)>
		<cfset local.runtimeLocale = createObject('java','java.util.Locale').getDefault() />
	</cfif>

	<cfset local.javaLocale = local.runtimeLocale.getLanguage() />
	<cfif len(local.runtimeLocale.getCountry().toString())>
		<cfset local.javaLocale = listAppend(local.javaLocale,local.runtimeLocale.getCountry().toString(),'_') />
	</cfif>

	<cfset setLocale(local.preservedLocale) />

	<cfreturn local.javaLocale />
</cffunction>


<cffunction name="railoJavaLocale" returnType="string" access="private" output="false" hint="Gets the java locale for Railo">
	<cfargument name="locale" type="string" required="false" default="#getLocale()#" hint="Locale to get the Java locale from" />

	<cfset local.javaLocale			= '' />
	<cfset local.runtimeLocale	= createObject('java','railo.runtime.i18n.LocaleFactory').getLocale(arguments.locale) />

	<cfset local.javaLocale = local.runtimeLocale.getLanguage() />
	<cfif len(local.runtimeLocale.getCountry().toString())>
		<cfset local.javaLocale = listAppend(local.javaLocale,local.runtimeLocale.getCountry().toString(),'_') />
	</cfif>

	<cfreturn local.javaLocale />
</cffunction>

</cfcomponent>
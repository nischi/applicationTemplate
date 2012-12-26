<cfcomponent accessors="true" extends="parent.crud" persistent="true" output="false" hint="userBean">

<cfproperty name="email"		ormType="string"	notNull="true"	length="250"	hint="E-Mail address the user may use for authentication" />
<cfproperty name="password"	ormType="string"	notNull="true"	length="250"	hint="Password the user may use for authentication" />

</cfcomponent>
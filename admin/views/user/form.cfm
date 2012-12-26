<cfset local.user = rc.user />


<cfoutput>
<form action="#buildURL('.save')#" method="POST">
	<input name="ident" id="ident" type="hidden" value="#local.user.getIdent()#" />

	<label for="email">#translate('user.email')#</label>
	<input name="email" id="email" type="email" value="#local.user.getEmail()#" />

	<label for="password">#translate('user.password')#</label>
	<input name="password" id="password" type="password" value="" />

	<label>#translate('user.isactive')#</label>
	<label for="isactive_yes">#translate('yes')#</label>
	<input name="isactive" id="isactive_yes" type="radio" value="1"<cfif local.user.getIsActive()> checked="checked"</cfif> />
	<label for="isactive_no">#translate('no')#</label>
	<input name="isactive" id="isactive_no" type="radio" value="0"<cfif NOT local.user.getIsActive()> checked="checked"</cfif> />

	<button type="submit">#translate('user.save')#</button>
</form>
</cfoutput>
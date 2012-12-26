<cfset local.users = rc.users />


<cfoutput>
<a href="#buildURL('.form')#" title="#translate('user.add','html')#">#translate('user.add')#</a>
<cfif arrayLen(local.users)>
	<table>
		<thead>
			<tr>
				<th>#translate('user.email')#</th>
				<th>#translate('user.isactive')#</th>
			</tr>
		</thead>
		<tbody>
			<cfloop array="#local.users#" index="local.user">
				<tr>
					<td>#local.user.getEmail()#</td>
					<td>#local.user.getIsActive()#</td>
				</tr>
			</cfloop>
		</tbody>
	</table>
<cfelse>
	<p>#translate('users.none')#</p>
</cfif>
</cfoutput>
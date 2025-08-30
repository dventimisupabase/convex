
# CONTEXT

## INSTRUCTIONS

You are a customer support engineer.  Your job is to help customers solve their issues by writing helpful, accurate, and timely responses, or internal comments to coordinate with colleagues.  First, you will be presented with a NEW SUPPORT TICKET.  Second, you will be presented with a series of PAST RESOLVED TICKETS which may offer relevant language, troubleshooting steps, or internal advice for dealing with the NEW SUPPORT TICKET.

Please generate the next OUTBOUND message for the NEW SUPPORT TICKET based on experience from PAST RESOLVED TICKETS.  Those PAST RESOLVED TICKETS have a TICKET MESSAGE HISTORY recording messages between customers and customer support engineers, and between customer support engineers and each other.  Messages from the customer to a customer support engineer are denoted with INBOUND.  Messages from a customer support engineer to the customer are denoted with OUTBOUND.  Private messages between customer support engineers are denoted with COMMENT.  This document and all of the related content is organized in Markdown format, and each TICKET in the series of PAST RESOLVED TICKETS is on its own separate Markdown document.

IMPORTANT:  When generating a response, don't draw attention to the fact that the response is based on similar tickets.

IMPORTANT:  In the signature block, replace the individual support engineer's name with [YOUR NAME HERE].

## NEW SUPPORT TICKET

## TICKET SUBJECT
Supabase client fails to refresh auth token woth 429 due to a wrongly set cookie domain

## TICKET DESCRIPTION

## TICKET MESSAGE HISTORY

### INCOMING
I'm hitting this very bug https://github.com/orgs/supabase/discussions/33008
I switched to supabase trying to enable multi-domain auth. The user tries to login to coach.domain.com gets redirected to www.domain.com and the sb-* auth cookie is set to the domain .www.domain.com. That throws the user in a redirect loop:

they go to coach.domain.com, which tries to refresh the token, can't find the cookie (because it's signed to .www.domain.com which doesn't include coach.domain.com

It keeps trying to fetch the "correct token" and cannot see that it already exists under the wrong domain.

Now we have users stuck in a loop with the bad cookie, and they keep hitting rate limit errors. Any ideas on how to get rid of these cookies to get the users out of this loop

### COMMENT
Ticket Info:

Project ID: tokgcmxvndfdrpsptxkc
Org Slug: ekepsszpfvbodyxtrgcn
Effective Org Plan: Pro
Severity: Low
Allow Support Access: True
Cloud Provider: AWS

Admin Studio Link - Project: https://admin-studio-internal-prod.supabase.xyz/projects?identifier=tokgcmxvndfdrpsptxkc
Admin Studio Link - Org: https://admin-studio-internal-prod.supabase.xyz/organization?identifier=ekepsszpfvbodyxtrgcn

### OUTGOING

Hi there,

Thanks for reaching out to us. We have received your support request and your ticket id is SU-230924.

As Pro plan, we will aim to respond to you in 1-2 business days; however, we are experiencing very high ticket volumes and may be delayed. You can also find community support using Github Discussions here:

https://github.com/supabase/supabase/discussions

We do offer priority support packages with designated customer success managers. If you are interested in a priority support package then feel free to reply to this email for more details.

Thanks,

The Supabase Team.

### COMMENT
[Ticket analysis](https://admin-studio-internal-prod.supabase.xyz/ticket?ticket_id=cnv_1icf6mn2) - 2025-08-04 17:26:33

Based on the ticket information and documentation, I can identify several technical issues related to the multi-domain authentication redirect loop problem:

## Root Cause Analysis

The primary issue appears to be **cookie domain misconfiguration** in a multi-domain setup where users authenticate on `coach.domain.com` but get redirected to `www.domain.com`, causing the auth cookie to be incorrectly set to `.www.domain.com` domain instead of the broader `.domain.com` domain.

## Key Technical Issues Identified

### 1. Cookie Domain Binding Problem
The auth cookie is being set with domain `.www.domain.com` instead of `.domain.com`, making it inaccessible from `coach.domain.com`. This is similar to the issue mentioned in the documentation about Twitter OAuth using cookies bound to specific domains.

**Relevant Documentation:**
- https://supabase.com/docs/guides/platform/custom-domains (mentions Twitter OAuth cookie domain binding issues)

### 2. Rate Limiting from Continuous Token Refresh
The redirect loop is causing continuous token refresh attempts that hit rate limits (429 errors), as mentioned in the ticket. This suggests the client is trapped in an authentication loop.

**Relevant Documentation:**
- https://supabase.com/docs/guides/auth/auth-rate-limits

### 3. Multi-Domain Authentication Configuration
The setup involves authentication across multiple domains (`coach.domain.com` and `www.domain.com`), which requires careful configuration of redirect URLs and cookie options.

**Relevant Documentation:**
- https://supabase.com/docs/guides/auth/redirect-urls
- https://supabase.com/docs/guides/auth/sessions/multi-subdomain-sso

### 4. Server-Side Token Refresh Issues
The documentation mentions that server-side requests may not have cookies set when using route prefetching, which could contribute to authentication issues.

**Relevant Documentation:**
- https://supabase.com/docs/guides/auth/server-side/creating-a-client (mentions session issues with Next.js route prefetching)

## Potential Solutions Based on Documentation

1. **Fix Cookie Domain Configuration**: Ensure cookies are set to `.domain.com` instead of `.www.domain.com` to make them accessible across all subdomains.

2. **Update Redirect URL Configuration**: Add all necessary redirect URLs to the allow list in the Supabase dashboard.

3. **Clear Problematic Cookies**: As mentioned in the ticket, clearing the incorrectly scoped cookies would free affected users from the loop.

4. **Review Cookie Options**: The `cookieOptions` configuration needs to be consistent across all domains in the multi-domain setup.

The issue is fundamentally a cookie scoping problem in a multi-domain authentication flow, exacerbated by rate limiting when the client gets stuck in a refresh loop.

Based on the ticket analysis, several playbooks are relevant to this multi-domain authentication issue:

## Relevant Playbooks:

### 1. **Authentication and User Management Playbook**
https://github.com/supabase/playbooks/tree/main/playbooks/auth/authentication-and-user-management-playbook.md

This playbook covers token refresh mechanisms and auto-refresh token behavior, which is directly relevant since the issue involves continuous token refresh attempts hitting rate limits.

### 2. **Rate Limit Exceeded Auth**
https://github.com/supabase/playbooks/tree/main/playbooks/auth/rate-limit-exceeded-auth.md

**Key steps to resolve:**
- Use Redash to check Auth configuration for anomalies
- Query Logflare Gotrue source for "rate limit exceeded" error messages
- Check rate limit settings in the dashboard and potentially increase them
- The playbook specifically mentions investigating 429 errors against endpoints

### 3. **Token Possible Abuse Attempt: 30691**
https://github.com/supabase/playbooks/tree/main/playbooks/auth/token-possible-abuse-attempt-30691.md

**Directly relevant to the issue:**
- This warning occurs when the same refresh token is used multiple times
- Common causes include sending session from client to server and using on both ends
- Suggests reviewing server-side rendering practices and disabling `persistSession` and `autoRefreshToken` on server-side clients
- Points to SSR documentation for best practices

### 4. **Magic Link Invalid Upon Receipt**
https://github.com/supabase/playbooks/tree/main/playbooks/auth/magic-link-otp-invalid-email-pre-fetching.md

While not directly about redirect loops, this playbook addresses single-use link issues that could contribute to authentication problems in multi-domain setups.

The most relevant playbooks are #2 and #3, which directly address the rate limiting and refresh token reuse issues described in the ticket.

Please give us feedback with a :thumbsup: or :thumbsdown: to help us improve our analysis.

### OUTGOING
Hi Hisham,

Thank you for reaching out and sharing the details of the issue you're experiencing. I understand how frustrating it can be to deal with a redirect loop and the complications with the auth cookies.

To assist you better, I recommend checking the cookie settings and ensuring that they are configured correctly for your domains. Additionally, <ANSWER HERE>.

If you need further assistance, please let me know, and I'll be happy to help.

Best,
David



## PAST RESOLVED TICKETS

---

## TICKET SUBJECT
enter supabase

## TICKET DESCRIPTION
Error: Auth session missing!

## TICKET MESSAGE HISTORY

### INCOMING
Email: mikhael.parent@eia.edu.co
Ticket name: enter supabase
Project reference: rnxrowpnoooimwksqnot
Organization slug: djeyjkaglugxxzejpccz
Allow support access: false
Severity: Low
Type: Dashboard bug
Ticket description: Error: Auth session missing!
Affected services: Authentication

### OUTGOING
Hey,

I did some research into this error and I want to rule out one more potential cause of this error. Are you using the listen events for Auth like onAuthStateChange? for more context: https://supabase.com/docs/reference/javascript/auth-onauthstatechange

Having multiple tabs with the same app open can cause this error for some frameworks. See an example here: https://github.com/nuxt-modules/supabase/issues/25#issuecomment-1106717392

This may be fixed on newer version of the Supabase packages if you are on an older version as well.

Can you please send us your package-lock.json or equivalent if not using react/nextjs please so we can verify your packages and versions to help investigate this further.

Best regards,
Monica Khoury​
Supabase Support Engineer


---

## TICKET SUBJECT
Feedback

## TICKET DESCRIPTION
supabase auth error

## TICKET MESSAGE HISTORY

### INCOMING
Email: alfath.noor17@gmail.com
Ticket name: Feedback
Project reference: cjehpcbatlwadmlocwlt
Allow support access: false
Type: Feedback
Ticket description: supabase auth error
dashboard_feedback_path: /project/cjehpcbatlwadmlocwlt/auth/users

### OUTGOING
Hi there,

Thank you for reaching out to Supabase Support.

In order to better assist you. Could you tell us what were you trying to do when you ran into this problem? Could you provide the below information?

- Screenshot/video of the error, or/and
- Screenshot of the network activity of your console

Kind Regards,
Sreyas Udayavarman
Supabase Support Engineer​


---

## TICKET SUBJECT
Supabase auth magic link not working

## TICKET DESCRIPTION
Supabase auth is no longer working. To my knowledge I changed nothing.

## TICKET MESSAGE HISTORY

### INCOMING
Email: andrewgardner@live.com
Ticket name: Supabase auth magic link not working
Project reference: xnnludnqhvioyigznnjo
Organization slug: pbnqcovsmfzcwrcavjwz
Allow support access: true
Severity: High
Type: Problem
Ticket description: Supabase auth is no longer working. To my knowledge I changed nothing.
Affected services: Authentication
Library: Javascript

### INCOMING
Feel free to close this I have fixed the problem (SMTP api key didn’t get updated)

### OUTGOING
Hi Andrew,

Thanks for your update.

I'll proceed to close this ticket for now. However, please don't hesitate to contact us again if you face any issues in the future. If you reply back to this ticket, it will automatically get reopened, and our team will be happy to assist you further.

Best regards,
Sreyas Udayavarman​
Supabase Support Engineer


---

## TICKET SUBJECT
Rolled out auth change causing broken sessions

## TICKET DESCRIPTION
I recently rolled out a change that intended to update supabase auth cookies to apply to the entire domain subframe.com instead of a subdomain app.subframe.com but some users appear to be caught in a refresh loop in cases where they have both sets of cookies on their client particularly when trying to refresh a token. This causes 429s on the supabase auth side. I haven't been able to figure out how to rollout code to affected clients that will rectify the issue - in particular signout seems broken because it calls refresh internally.

## TICKET MESSAGE HISTORY

### INCOMING
Email: aginzberg@subframe.com
Ticket name: Rolled out auth change causing broken sessions
Project reference: dbgjvucxjwkukwbojywe
Organization slug: sleepy-aquamarine-n7td8x8
Allow support access: true
Severity: High
Type: Problem
Ticket description: I recently rolled out a change that intended to update supabase auth cookies to apply to the entire domain subframe.com instead of a subdomain app.subframe.com but some users appear to be caught in a refresh loop in cases where they have both sets of cookies on their client particularly when trying to refresh a token. This causes 429s on the supabase auth side. I haven't been able to figure out how to rollout code to affected clients that will rectify the issue - in particular signout seems broken because it calls refresh internally.
Affected services: Authentication
Library: Javascript

### INCOMING
Potentially interested in a priority support package would just want to
understand the pricing

### INCOMING
We also rolled out a custom domain a week ago - and it seems like a number
of clients have old cookies using the previous url which is also causing
overly large header issues. One potential solution would just remove all
supabase auth cookies on all clients and ask them to sign in again - just
not sure how to implement that safely...

### INCOMING
This is becoming a problem for nearly all of our users, can we please
escalate this?

### OUTGOING
Hey Adam​,

Thank you for contacting Supabase support. Please note that support for Pro plan is best effort only without any SLA. In the teams plan, you would get 1 Day SLA support. (We are usually much faster, but that's the SLA for the plan).

Can you also share how you are trying to sign out the users with some snippets of how these changes were made and how it is working now?
Also, if the users delete old cookies or user another browser, are they able to log in? I think that maybe you'll need to roll a code to identify and clear old cookies in the client.

Best regards,
Rodrigo Martins Mansueli​
Supabase Support Engineer

### INCOMING
Got it.

We currently have the following which doesn't seem to be working reliably.
In addition to 429s we've also seen Refresh Token Not Found. Obviously
we're only running this when hitting an error but wanted to work with you
all before doing anything more invasive. As I mentioned we're also seeing
issues with overly large headers because of the supabase cookies not being
deleted so it would be nice to clean them up holistically - both the ones
associated with app.subframe.com and the ones with the old non-custom
domain.

const { error, data } = await supabase.auth.getSession()
if (error) {
if (error.status === 429) {
logger.trackWarning("Supabase rate limit hit, attempting to clear old
cookies", { message: error.message })
document.cookie = serialize("sb-api-auth-token.0", "", {
...DEFAULT_COOKIE_OPTIONS,
domain: "app.subframe.com",
maxAge: 0,
})
document.cookie = serialize("sb-api-auth-token.1", "", {
...DEFAULT_COOKIE_OPTIONS,
domain: "app.subframe.com",
maxAge: 0,
})
await supabase.auth.signOut()
}
}

### OUTGOING
Thanks for sharing this, Adam.

I am escalating this to the Auth team as they can provide you with more details on best practices.
Please understand that you may have slower responses due to the weekend.

Best regards,
Rodrigo Martins Mansueli
Supabase Support Engineer

### OUTGOING
Hi Adam,

Please indicate all or any libraries you're using for cookies. Are you using auth-helpers, ssr? If yes, please send over middleware.ts files if using NextJS or any other equivalent middleware / shared-code for SSR libraries.

In the code snippet you sent over, you handle a 429 with clearing cookies -- why is this? 429 indicates that you should implement a slow-down mechanism on your frontend, such as asking a user to submit their credentials / OTP a bit later and be prevented from clicking a button which would cause further API requests.

> We also rolled out a custom domain a week ago - and it seems like a number of clients have old cookies using the previous url which is also causing overly large header issues.

Note that Supabase Auth cookies, depending on your implementation, are not domain specific. We use localStorage by default, which helps get rid of this issue. Could you please share any code relating to how you set cookies?

Awaiting your answers to help you out more.

Best,
Stojan from the Auth team

### INCOMING
Hi Stojan,

Main app url: app.subframe.com - *Not NextJS *deployed on vercel
Marketing site url: subframe.com - NextJS app deployed on vercel

We're using ssr now. Here's the full timeline.

4/2 - Migrated to @supabase/ssr 0.1.0
4/11 - Swapped production to use a custom domain (supabase "custom domain"
i.e. dbgjvucxjwkukwbojywe -> api.subframe.com)
4/18 - Updated app cookies to set an explicit domain of subframe.com so
that we can access auth state on the marketing site

And here's my understanding of the auth state on our clients
Before 4/2 - local storage
4/2 - 4/11 - cookies that look like sb-dbgjvucxjwkukwbojywe-auth-token
4/11 - 4/18 - cookies that look like sb-api-auth-token, domain =
app.subframe.com (implicitly set)
4/18+ - cookies that look like sb-api-auth-token, domain = subframe.com
(explicitly set)

Relevant snippets:
export const COOKIE_OPTIONS = process.env.NODE_ENV === "production" ? {
domain: "subframe.com" } : undefined

import { createBrowserClient } from "@supabase/ssr"

export let supabase = createBrowserClient<SupabaseDatabase>(SUPABASE_URL,
SUPABASE_ANON_KEY, {
cookies: {},
cookieOptions: COOKIE_OPTIONS,
auth: {
debug: true,
},
})

app.subframe.com middleware:

import { RequestCookies, ResponseCookies } from "@edge-runtime/cookies"
import { type CookieOptions, createServerClient } from "@supabase/ssr"
import { next } from "@vercel/edge"
import { ensureExists } from "helpers"
import { setAuthHeaders } from "./src/server/auth-helpers"
import { SUPABASE_ANON_KEY, SUPABASE_URL } from
"./src/supabase-client/constants"
import { COOKIE_OPTIONS } from "./src/supabase-client/cookie-options"
import { SupabaseDatabase } from "./src/supabase-client/supabase-types"

export const config = {
/*
* We perform signature validation inside of /api/webhook/stripe and
/api/webhook/supabase
*/
matcher: "/api/((?!webhook).*)",
}

export default async function middleware(req: Request) {
const requestCookies = new RequestCookies(req.headers)
const headers = new Headers()
const responseCookies = new ResponseCookies(headers)
const supabase = createServerClient<SupabaseDatabase>(SUPABASE_URL,
SUPABASE_ANON_KEY, {
cookies: {
get(name: string) {
return requestCookies.get(name)?.value
},
set(name: string, value: string, options: CookieOptions) {
responseCookies.set(name, value, options)
},
remove(name: string, options: CookieOptions) {
responseCookies.set(name, "", options)
},
},
cookieOptions: COOKIE_OPTIONS,
})

// Split out the user request separately as this will refresh the token if
needed.
const userResponse = await supabase.auth.getUser()
if (userResponse.error) {
return new Response(null, { headers, status: 401 })
}

const teamResponse = await supabase.from("teams").select()
if (teamResponse.error) {
return new Response(null, { headers, status: 401 })
}

setAuthHeaders(req.headers, {
user: { id: userResponse.data.user.id, email: ensureExists(userResponse.data
.user.email) },
team: { id: teamResponse.data[0].id },
})

return next({ headers, request: { headers: req.headers } })
}

subframe.com middleware (new as of 4/18)

import { type CookieOptions, createServerClient } from "@supabase/ssr"
import { NextRequest, NextResponse } from "next/server"
import { SUPABASE_ANON_KEY, SUPABASE_URL } from
"web/src/supabase-client/constants"
import { COOKIE_OPTIONS } from "web/src/supabase-client/cookie-options"
import { SupabaseDatabase } from "web/src/supabase-client/supabase-types"

const REDIRECT_URL = process.env.NODE_ENV === "production" ? "
https://app.subframe.com" : "http://localhost:3000"

export const config = {
matcher: [
/*
* Match all request paths except for the ones starting with:
* - _next/static (static files)
* - _next/image (image optimization files)
* - favicon.ico (favicon file)
* Feel free to modify this pattern to include more paths.
*/
"/((?!_next/static|_next/image|favicon.ico|.*\\
.(?:svg|png|jpg|jpeg|gif|webp)$).*)",
],
}

export default async function middleware(request: NextRequest) {
let response = NextResponse.next({
request: {
headers: request.headers,
},
})

const supabase = createServerClient<SupabaseDatabase>(SUPABASE_URL,
SUPABASE_ANON_KEY, {
cookies: {
get(name: string) {
return request.cookies.get(name)?.value
},
set(name: string, value: string, options: CookieOptions) {
request.cookies.set({
name,
value,
...options,
})
response = NextResponse.next({
request: {
headers: request.headers,
},
})
response.cookies.set({
name,
value,
...options,
})
},
remove(name: string, options: CookieOptions) {
request.cookies.set({
name,
value: "",
...options,
})
response = NextResponse.next({
request: {
headers: request.headers,
},
})
response.cookies.set({
name,
value: "",
...options,
})
},
},
cookieOptions: COOKIE_OPTIONS,
})

const { error } = await supabase.auth.getUser()
if (!error) {
return NextResponse.redirect(REDIRECT_URL)
}

return response
}

My best guess of what is happening is that in cases where people logged in
between 4/11 - 4/18 and then again after 4/18 they ended up with two sets
of cookies with the same name but different domains

sb-api-auth-token, domain = app.subframe.com
sb-api-auth-token, domain = subframe.com

I don't totally understand why this state would break supabase auth...
hoping you can help me understand.

At this point most of the damage has been done - and we've reached out to
customers that hit the issue and asked them to clear their cookies and then
everything is fine. There are also likely a handful of customers which may
be ticking time bombs who will likely hit this in the coming days / weeks.

There is a latent issue where older customers have way too many cookies
which are quite sizable and it would be great to clear those out to avoid
getting header size issues with some of our services (vercel, logrocket).

Adam

### INCOMING
Hi Stojan,

Still haven't heard back from you. We're also sporadically seeing
"Invalid Refresh Token: Refresh Token Not Found". Have seen a number
of github issues related to that, such as
https://github.com/supabase/auth-helpers/issues/436. Is there a
resolution or best practice yet?

Adam

### OUTGOING
Hi Adam,

Kang Ming from the Auth team here.

> My best guess of what is happening is that in cases where people logged in between 4/11 - 4/18 and then again after 4/18 they ended up with two sets of cookies with the same name but different domains

You're spot on here - users with the old cookie set to app.subframe.com won't be authenticated on subframe.com since the cookie domain is set to a subdomain. I looked through the code snippets you sent and just to confirm, are the COOKIE_OPTIONS used in both the middleware in app.subframe.com and subframe.com when you call createServerClient both setting the domain to subframe.com? I think you are being caught in a refresh token loop because the cookie name is the same even though the domain set is different, have you tried setting a different cookie name through the cookie options yet?

Cheers,
Kang Ming

### INCOMING
Hi Kang Ming,

Thank you for your response.

### OUTGOING
Hi Adam,

1. What's the best way to delete supabase cookies from clients?
2. The best way would be to sign out the user by deleting their sessions. Alternatively, you can also try setting the "Clear-Site-Data" header on the response returned in the next middleware (https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Clear-Site-Data)
3. "Invalid Refresh Token: Refresh Token Not Found" error
4. We're still investigating this issue but this can be caused by a number of factors - it could be that the user's session was revoked (either by signing out or because the auth service detected an old ancestor refresh token being reused).

Cheers,
Kang Ming


---

## TICKET SUBJECT
Supabase Auth

## TICKET DESCRIPTION
Having issues with supabase auth, followed documentation closely still repeatably signed out, also need help grabbing user session on frontend client side

## TICKET MESSAGE HISTORY

### INCOMING
Email: engineering@mueshi.io
Ticket name: Supabase Auth
Project reference: tkykcxgbouzcmtljniyz
Organization slug: mafsxytblpinrxaqsygc
Allow support access: false
Severity: High
Type: Problem
Ticket description: Having issues with supabase auth, followed documentation closely still repeatably signed out, also need help grabbing user session on frontend client side
Affected services: Authentication
Library: Javascript

### OUTGOING
Hey there​,

Thank you for contacting Supabase support. I am sorry to hear you are having issues with the Auth process. Can you give me some details on how frequently you are being signed out and how are you reproducing it?

Also just to rule this out but have you modified the value for the Access Token(JWT) expiry time on this page (https://supabase.com/dashboard/project/_/settings/auth)?

For getting the user session on the client frontend, here is how you would get that data: https://supabase.com/docs/reference/javascript/auth-getsession

Please let us know if you run into any further issues or have questions. We will be happy to help you.

Best regards,
Peter Lyn​
Supabase Support Engineer




Recently, GitHub Pages [began supporting HTTPS](https://twitter.com/benbalter/status/444555263195217920) for `*.github.io` domains, like [this one](https://cfpb.github.io/) and [this one](https://sunlightlabs.github.io/congress/). 

In my opinion, this is a **huge** deal - GitHub Pages is the only major, free, general-purpose web host which also offers a secure channel. Given [how many simple and powerful uses](https://konklone.com/post/the-power-and-potential-of-github-pages) GitHub Pages has, and how vital secure and confidential connections are to the future of the web, I see this as a big step forward for developers, GitHub, and everyday people.

There are two catches: you *can't* force your site to only run over HTTPS, and you *can't* use HTTPS for custom domains.

But there's a lot you **can** do! Let's work around the problems.

### Defaulting to HTTPS

If you have a GitHub Pages site, and you'd like it to run as close to HTTPS-only as possible:

* Always link to your own site using its `https://` URL. Go through any supporting sites or blog posts or material and update the link.
* If there are any external and prominent links to your site, ask the site owner to update their link to use `https://`.
* If you're a go-getter, do a GitHub search for [anyone linking to your domain](https://github.com/search?q=%22sunlightlabs.github.io%22&ref=cmdform&type=Code), and file some quick in-browser PRs to switch people's links.

But none of those are important as...

### Forcing a redirect

So, how do you force a redirect for a static site when you don't control the server? You can't use a `<meta refresh>` tag, because you can't change what HTML gets delivered per-protocol.

The only choice is to **do it in JavaScript**. Put the following at the top of your HTML, replacing `YOURDOMAIN` with your user or organization name:

<script src="https://gist.github.com/konklone/9968713.js"></script>

The above hack will immediately redirect any users who visit your domain on an insecure protocol to a secure protocol. It won't affect visitors on any other domain (like `localhost`). This is what we're doing at the [Sunlight Foundation](https://sunlightfoundation.com) now for the documentation for our [Sunlight Congress API](https://sunlightlabs.github.io/congress/).

Make no mistake, client-side redirecting is a hack and an imperfect solution by any means. It's also not secure! But the whole point is to make sure that the links other people make to your website going *forward* are the secure kind. The more links that you and others make that go directly to `https://`, the less often the redirect will need to be triggered.

If you're using Jekyll, you may wish to [follow my example](https://github.com/sunlightlabs/congress/commit/6426761a671d46df6fc5d2526bdaf506c39d789c) of using a `site.enforce_ssl` parameter, or you can just hardcode it like above. It'd be nicer if this could get baked into a Jekyll plugin, but GitHub Pages only supports a couple of whitelisted plugins. If you're interested in the issue, [ring in on this ticket](https://github.com/jekyll/jekyll-redirect-from/issues/18#issuecomment-37875647) to discuss how best to widen deployment of HTTPS-by-default on GitHub Pages.

### Using your custom domain

Well, there's no easy, free way to work around this one. **_Yet_**! 

[Cloudflare](https://www.cloudflare.com/) will happily sit in front of your domain and terminate SSL for you, but right now they charge $20 per site per month. But Cloudflare is [on a mission to double SSL on the web by 2014](http://www.theverge.com/2013/12/17/5217800/cloudflare-pledges-to-double-ssl-usage-on-the-web-in-2014), and they plan to do it by [offering SSL termination for free](https://twitter.com/CloudFlare/status/450390445365800961). That will be a serious gamechanger, not just for GitHub Pages but for the whole Internet.

So for now, consider this part of the post a placeholder: soon, there will be riches. In the meantime, I encourage you to watch for the announcement by following their [seriously excellent blog](http://blog.cloudflare.com/).

### What GitHub can do

It's unlikely that GitHub is going to create the infrastructure needed to natively support custom domains, and Cloudflare's leadership will render that less of a problem. 

However, there's still a few things GitHub could do to lower the barrier to using HTTPS and to make people more aware of it.

* **Document the feature.** There's no formal announcement or description of SSL for GitHub Pages; it could disappear anytime. It's worth a quick blog post and a help page, to cement GitHub's commitment and describe how to avoid common mixed content pitfalls.
* **Shore up the SSL configuration.** `github.com`'s SSL is [world-class](https://www.ssllabs.com/ssltest/analyze.html?d=github.com&s=192.30.252.128&hideResults=on), but `github.io`'s could still [use some tweaks](https://www.ssllabs.com/ssltest/analyze.html?d=sunlightlabs.github.io) around forward secrecy and cipher choices.
* Most importantly, **let users turn HTTPS on by default**, with a checkbox in their settings. That would render the entire hack above unnecessary, and lead a lot more people to Just Do It. In fact, turn on the checkbox by default for new users, and for existing users who don't yet have any GitHub Pages!

2014 may well be the Year of SSL, and GitHub is fertile ground for expanding the playing field. In the meantime, I've been going around [filing PRs](https://github.com/project-open-data/project-open-data.github.io/pull/295) and [opening tickets](https://github.com/cfpb/cfpb.github.io/issues/22) with GitHub Pages sites I care about, to squash mixed-content warnings and ensure they're HTTPS-ready. Go adopt some sites you know on GitHub Pages and do the same!
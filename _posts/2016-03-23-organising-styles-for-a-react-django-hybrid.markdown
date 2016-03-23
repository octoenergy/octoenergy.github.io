---
title: Organising styles for a React/Django hybrid
layout: post
author: Ashley Firth
---

When we started working with React JS here at Octopus Energy, I thought I'd try
implementing [CSS Modules](https://github.com/css-modules/css-modules) to
achieve what they call 'interoperable CSS'.

It works especially well with React components, which are re-usable units of
mark-up and Javascript functionality. Using CSS modules allows a component's
styles to be bundled with the component so they can be re-used through your
site.

I used CSS modules as a PostCSS plugin and, with a few more plugins to handle
things like mixins, nesting, and variables, I was ready to go.

Briefly, CSS Modules can be used with a React component as follows. Given a stylesheet for a component:

{% highlight css %}
/* component.css */
.className {
    color: green;
}
{% endhighlight %}

you can reference it in your component JSX file:

{% highlight js %}
/* Component.jsx */
import styles from "./component.css";
{% endhighlight %}

and reference the styles in the JSX:

{% highlight js %}
/* Component.jsx */
return (
	<h1 class={styles.className}>Hello word</h1>
	<p className={styles.className}>Lorem ipsum dolor sit amet</p>
);
{% endhighlight %}

Finally, during compilation, the CSS modules will ensure each reference is unique:

{% highlight css %}
.className__abc5436,
.className__def6547 {
	color: green;
}
{% endhighlight %}
{% highlight html %}
<h1 class="className__abc5436">Hello word</h1>
<p class="className__def6547">Lorem ipsum dolor sit amet</p>
{% endhighlight %}

*For a more detailed introduction to [CSS Modules: Welcome to the Future](http://glenmaddern.com/articles/css-modules) by Glen Maddern*

The benefits were pretty immediate. I had a `.css` file to accompany every
component `.jsx` file and I could use the sort of vague classnames you would
never dream of using in a regular CSS file. Suddenly `.Image` was an
acceptable selector in the context, and one that wouldn't result in me being
killed by another front end developer. The use of `@extend` prevented code
duplication inside the component file, and allowed me to use styles from another
file if I was happy with reducing the level of encapsulation a little.

However encapsulation means just that; totally encapsulated. 

## The issue

It's important to note that the downside to CSS modules in this context is
entirely our own doing. There were instances where React either wasn't the best
approach or wasn't necessary for a particular section of the site. We have a lot
of skilled Python developers at Octopus Energy and so it's always smart to
utilise that. Regardless of what is going on behind the scenes though, the front
end is always expected to be consistent. However, I was now in the position where
I had no way to access the randomly generated hash in the CSS selector that CSS
modules creates and use it in a Django template.

Specifically, this part:
{% highlight css %}
__abc5436
{% endhighlight %}

of this class name:
{% highlight css %}
.className__abc5436 {
	
}
{% endhighlight %}

is dynamically injected before the page is rendered. I could try and guess the
hash but I may as well have bought a lottery ticket and expected the same
outcome - an unstyled component and no extra money.

##The attempted workaround

So I had CSS siloed in modular component files and areas of the site that now
wanted to use those styles that weren't React-based. In an attempt to prevent
excessive duplication between the two, I created a `Sitewide.css` file that both
the CSS modules and the SASS (used for the rest of the site/global styles) could
extend from. The downside to this approach is two-fold:  
  
1) The styles in this file had to be written in pure CSS as SASS and PostCSS have different syntax for mixins and variables.  
  
2) As pure CSS, the bigger the file becomes the less maintainable it is without the use of pre-processor features such as variables, nesting, and mixins.

Therefore, for future code quality, I had to remove CSS modules from the setup
and replace it with SASS globally. However its approach did teach me some good
techniques that I brought over to the custom approach we use now.

## The new approach

We use a version of the [7-1 pattern](http://sass-guidelin.es/#the-7-1-pattern)
to lay out our styles and directories (although ours is only 5-1). It looks like
this:

{% highlight html %}
sass/
|
|- base/
|    |- _global.scss    # Global rules
|    |- _type.scss      # Typography rules
|
|
|- components/
|    |- # Pattern exactly mimics app/components
|    |- # with one .scss file for each component
|    |- common/
|    |- join-wizard/
|    |- quote-wizard/
|    |- style-guide/
|
|
|- layout/
|    |- _alerts.scss    # Alerts
|    |- _buttons.scss   # Buttons
|    |- _forms.scss     # Forms
|    |- _grid.scss      # Grid (Bootstrap + our styles)
|    |- _links.scss     # Links
|    |- _lists.scss     # Lists
|    |- _nav.scss       # Nav
|    |- _print.scss     # Print specific styles
|    |- _tables.scss    # Tables
|    |- _wells.scss     # Wells
|
|
|- pages/
|    |- # Styles for any page specific rules
|    |- # (One file per section)
|    |- _dashboard.scss
|
|
|- utils/
|    |- _mixins.scss    # Mixins
|    |- _variables.scss # Variables
|
|
|- styles.scss          # Main Sass file
{% endhighlight %}

Although all styles are technically 'global' now, we try and make each component as encapsulated as possible, enabling it to be used throughout the application with no visible changes in appearance occuring. 

To achieve this, we have a set of rules when styling components new or existing. The rules are as follows:

##The rules

###1. Mimic the React component layout

As you can see from the structure above, Within `sass/`, we have a `components/` directory that mimics the layout of the React components folder in `app/components`. Although this isn't in the same directory as the JS, it still maintains CSS modules' idea of style separation. The effect is you still always know where to find the styles specific to a React component; it has the same name!

###2. Never use global classes

Each selector in a component `.scss` file will start with the name of the component followed by the class name. i.e. if we were creating a `button` class in a container called `JoinComponent`, the class selector in `_JoinComponent.scss` would be:

{% highlight css %}
.JoinComponent-button {
  
}
{% endhighlight %}

This way, the button styles is exclusive to the `JoinComponent` component, and would not be caught up in specificity issues or accidentally overridden in another file.

###3. If it's commonly used, always `@extend` it

If your component uses a common piece of styling, such as a button or link, create a new component-specific selector and use the SASS `@extend` syntax to bring in the style. You need to do this even if you aren't doing anything to edit the styles of it.

So for our above example, if `JoinComponent-button` was intended for use in the component to look like a standard button, the code would be:

{% highlight css %}
.JoinComponent-button {
  @extend .button;
  /* any new styles if applicable */
}
{% endhighlight %}

This may seem like overkill if your component uses many common app styles, but it ensures that component selectors remain totally isolated and will never clash with one another. It does technically mean that everything you need to style the component does not lie solely in the file, but it would still look the same if it were used anywhere in the site. Additionally, it prevents code duplication.

  
###4. Do not nest classes

This rule only applies to component-specific `.scss` files. The reasoning behind this is that your layers of specificity remain low, as you avoid cases where classes only get certain styling when they are inside other classes etc. Therefore if you ever changed the heirarchy of the component markup, it would break the styling.

You are allowed to style anything inside a class that is a regular HTML component (paragraph or anchor tags for example), but instead of nesting classes, simply create them as two separate selectors. The fact that each component selector starts with the component's name also means that you can be vague in your selector names and not worry that the style will affect other areas of the app:

{% highlight scss %}
/* Instead of this: */
.well {
  background-color: white;

  .well-title {
    color: green;
  }
}

/* Do this: */
.Component-well {
  background-color: green;
}
.Component-title {
  color: green;
}
{% endhighlight %}

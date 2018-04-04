

console.log('loading landing-page.js');
// this will either smooth scroll to an anchor where the `name`
// is the same as the `scroll-to` reference, or to a px height
// (as specified like `scroll-to='0px'`).
var ScrollTo = function () {
    $("[scroll-to]").click(function () {
        var sel = $(this).attr("scroll-to");

        // if the `scroll-to` is a parse-able pixel value like `50px`,
        // then use that as the scrollTop, else assume it is a selector name
        // and find the `offsetTop`.
        var top = /\dpx/.test(sel) ?
                parseInt(sel, 10) :
                $("[name='" + sel + "']").offset().top;

        $("body").animate({ scrollTop: top + "px" }, 300);
    });
};

export function path_parts() {
    return window.location.pathname.split('/').filter(function (chunk) {
        return chunk !== '';
    });
}

var hello_events = function () {
  console.log('hello_events');
    var counter = 0;
    $(window).scroll(function () {
        if (counter % 2 === 0) {
            $(".screen.hero-screen .message-feed").css("transform", "translateY(-" + $(this).scrollTop() / 5 + "px)");
        }
        counter += 1;
    });

    $(".footer").addClass("hello");
};

var events = function () {
    ScrollTo();

    $("a").click(function (e) {
        // if a user is holding the CMD/CTRL key while clicking a link, they
        // want to open the link in another browser tab which means that we
        // should preserve the state of this one. Return out, and don't fade
        // the page.
        if (e.metaKey || e.ctrlKey) {
            return;
        }

        // if the pathname is different than what we are already on, run the
        // custom transition function.
        if (window.location.pathname !== this.pathname && !this.hasAttribute("download") &&
            !/no-action/.test(this.className)) {
            e.preventDefault();
            $(".portico-landing").removeClass("show");
            setTimeout(function () {
                window.location.href = $(this).attr("href");
            }.bind(this), 500);
        }
    });

    var location = window.location.pathname.replace(/\/#*$/, "").split(/\//).pop();
    console.log('location', location);

    $("[on-page='" + location + "']").addClass("active");

    $("body").click(function (e) {
        var $e = $(e.target);

        if ($e.is("nav ul .exit")) {
            $("nav ul").removeClass("show");
        }

        if ($("nav ul.show") && !$e.closest("nav ul.show").length && !$e.is("nav ul.show")) {
            $("nav ul").removeClass("show");
        }
    });

    $(".hamburger").click(function (e) {
        $("nav ul").addClass("show");
        e.stopPropagation();
    });

    if (path_parts().includes('pages')) {
        hello_events();
    }
};

// run this callback when the page is determined to have loaded.
var load = function () {
    // show the .portico-landing when the document is loaded.
    setTimeout(function () {
        $(".portico-landing").addClass("show");
    }, 200);

    // display the `x-grad` element a second after load so that the slide up
    // transition on the .portico-landing is nice and smooth.
    setTimeout(function () {
        $("x-grad").addClass("show");
    }, 1000);

    // Set up events / categories / search
    events();
};

if (document.readyState === "complete") {
    load();
} else {
    $(load);
}

$(function () {
    if (window.location.pathname === '/team/') {
        render_tabs();
    }
});

// Prevent Firefox from bfcaching the page.
// According to https://developer.mozilla.org/en-US/docs/DOM/window.onunload
// Using this event handler in your page prevents Firefox from caching the
// page in the in-memory bfcache (backward/forward cache).
$(window).on('unload', function () {
    $(window).unbind('unload');
});

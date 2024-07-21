module [
    normal,
    sidebar,
]

import Views.Pages

# TODO this should be a module parameter
staticBaseUrl = "static"

headerTemplate : Str
headerTemplate = Views.Pages.header {
    staticBaseUrl,
    authors: "Themesberg",
    description: "Get started with a free and open-source admin dashboard layout built with Tailwind CSS and Flowbite featuring charts, widgets, CRUD layouts, authentication pages, and more",
    stylesheet: Views.Pages.stylesheet { staticBaseUrl },
    title: "Tailwind CSS Admin Dashboard - Flowbite",
}

# TODO restore the footer
#footerTemplate : Str
#footerTemplate = Views.Pages.footer {
#    copyright: "",
#}

navbarTemplate : Str
navbarTemplate = Views.Pages.navbar {
    relURL: "",
    staticBaseUrl,
}

sidebarTemplate : Str
sidebarTemplate = Views.Pages.sidebar {
    ariaLabel: "Sidebar",
}

normal : Str -> Str
normal = \content ->
    Views.Pages.layoutNormal {
        header: headerTemplate,
        content: content,
        footer: "",
        navbar: "",
    }

sidebar : Str -> Str
sidebar = \content ->
    Views.Pages.layoutSidebar {
        header: headerTemplate,
        content,
        footer: "",
        navbar: navbarTemplate,
        sidebar: sidebarTemplate,
    }

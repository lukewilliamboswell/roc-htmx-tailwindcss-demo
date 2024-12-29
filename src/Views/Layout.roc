module [
    normal,
    sidebar,
]

import Views.Pages

header_template : Str
header_template = Views.Pages.header {
    authors: "Themesberg",
    description: "Get started with a free and open-source admin dashboard layout built with Tailwind CSS and Flowbite featuring charts, widgets, CRUD layouts, authentication pages, and more",
    stylesheet: Views.Pages.stylesheet {},
    title: "Tailwind CSS Admin Dashboard - Flowbite",
}

# TODO restore the footer
# footerTemplate : Str
# footerTemplate = Views.Pages.footer {
#    copyright: "",
# }

navbar_template : Str
navbar_template = Views.Pages.navBar {
    relURL: "",
}

sidebar_template : Str
sidebar_template = Views.Pages.sidebar {
    ariaLabel: "Sidebar",
}

normal : Str -> Str
normal = \content ->
    Views.Pages.layoutNormal {
        header: header_template,
        content: content,
        footer: "",
        navbar: "",
    }

sidebar : Str -> Str
sidebar = \content ->
    Views.Pages.layoutSidebar {
        header: header_template,
        content,
        footer: "",
        navbar: navbar_template,
        sidebar: sidebar_template,
    }

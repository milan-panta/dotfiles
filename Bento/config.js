// ╔╗ ╔═╗╔╗╔╔╦╗╔═╗
// ╠╩╗║╣ ║║║ ║ ║ ║
// ╚═╝╚═╝╝╚╝ ╩ ╚═╝
// ┌─┐┌─┐┌┐┌┌─┐┬┌─┐┬ ┬┬─┐┌─┐┌┬┐┬┌─┐┌┐┌
// │  │ ││││├┤ ││ ┬│ │├┬┘├─┤ │ ││ ││││
// └─┘└─┘┘└┘└  ┴└─┘└─┘┴└─┴ ┴ ┴ ┴└─┘┘└┘

const CONFIG = {
  // ┌┐ ┌─┐┌─┐┬┌─┐┌─┐
  // ├┴┐├─┤└─┐││  └─┐
  // └─┘┴ ┴└─┘┴└─┘└─┘

  // General
  name: "",
  imageBackground: false,
  openInNewTab: false,
  twelveHourFormat: false,

  // // Greetings
  // greetingMorning: "Good Morning!",
  // greetingAfternoon: "Good Afternoon!",
  // greetingEvening: "Good Evening!",
  // greetingNight: "Go to Sleep!",

  // Layout
  bentoLayout: "lists", // 'bento', 'lists', 'buttons'

  // Weather
  weatherKey: "1b678a4113498d4b69e2b4934e786890", // Write here your API Key
  weatherIcons: "Nord", // 'Onedark', 'Nord', 'Dark', 'White'
  weatherUnit: "C", // 'F', 'C'
  language: "en", // More languages in https://openweathermap.org/current#multi

  trackLocation: false, // If false or an error occurs, the app will use the lat/lon below
  defaultLatitude: "43.653225",
  defaultLongitude: "-79.383186",

  // Autochange
  autoChangeTheme: true,

  // Autochange by OS
  changeThemeByOS: true,

  // Autochange by hour options (24hrs format, string must be in: hh:mm)
  changeThemeByHour: false,
  hourDarkThemeActive: "18:30",
  hourDarkThemeInactive: "07:00",

  // ┌┐ ┬ ┬┌┬┐┌┬┐┌─┐┌┐┌┌─┐
  // ├┴┐│ │ │  │ │ ││││└─┐
  // └─┘└─┘ ┴  ┴ └─┘┘└┘└─┘

  firstButtonsContainer: [
    {
      id: "1",
      name: "Github",
      icon: "github",
      link: "https://github.com/",
    },
    {
      id: "2",
      name: "Mail",
      icon: "mail",
      link: "https://outlook.office.com/mail/",
    },
    {
      id: "3",
      name: "Todoist",
      icon: "glasses",
      link: "https://q.utoronto.ca",
    },
    {
      id: "4",
      name: "Calendar",
      icon: "trello",
      link: "https://trello.com/",
    },
    {
      id: "5",
      name: "Reddit",
      icon: "calendar",
      link: "https://calendar.google.com/calendar/u/0/r",
    },
    {
      id: "6",
      name: "Odysee",
      icon: "youtube",
      link: "https://odysee.com/",
    },
  ],

  secondButtonsContainer: [
    {
      id: "1",
      name: "Music",
      icon: "headphones",
      link: "https://open.spotify.com",
    },
    {
      id: "2",
      name: "twitter",
      icon: "twitter",
      link: "https://twitter.com/",
    },
    {
      id: "3",
      name: "bot",
      icon: "bot",
      link: "https://discord.com/app",
    },
    {
      id: "4",
      name: "Amazon",
      icon: "shopping-bag",
      link: "https://amazon.com/",
    },
    {
      id: "5",
      name: "Hashnode",
      icon: "pen-tool",
      link: "https://hashnode.com/",
    },
    {
      id: "6",
      name: "Figma",
      icon: "figma",
      link: "https://figma.com/",
    },
  ],

  // ┬  ┬┌─┐┌┬┐┌─┐
  // │  │└─┐ │ └─┐
  // ┴─┘┴└─┘ ┴ └─┘

  // First Links Container
  firstlistsContainer: [
    {
      icon: "laptop",
      id: "1",
      links: [
        {
          name: "FSO",
          link: "https://fullstackopen.com/en/",
        },
        {
          name: "TheBook",
          link: "file:///Users/milan/.rustup/toolchains/stable-aarch64-apple-darwin/share/doc/rust/html/book/ch00-00-introduction.html",
        },
        {
          name: "UPython",
          link: "https://www.udemy.com/course/100-days-of-code/",
        },
        {
          name: "Notion",
          link: "https://www.notion.so",
        },
      ],
    },
    {
      icon: "github",
      id: "2",
      links: [
        {
          name: "Quercus",
          link: "https://q.utoronto.ca/",
        },
        {
          name: "Ideas",
          link: "https://www.notion.so/Ideas-2c8afb97fbc545fc88ec55617be196f0",
        },
        {
          name: "Internships",
          link: "https://github.com/SimplifyJobs/Summer2024-Internships",
        },
        {
          name: "Canadian",
          link: "https://github.com/jenndryden/Canadian-Tech-Internships-Summer-2024",
        },
      ],
    },
  ],

  // Second Links Container
  secondListsContainer: [
    {
      icon: "binary",
      id: "1",
      links: [
        {
          name: "Array",
          link: "https://www.youtube.com/playlist?list=PLgUwDviBIf0rENwdL0nEH0uGom9no0nyB",
        },
        {
          name: "BinSearch",
          link: "https://www.youtube.com/playlist?list=PLgUwDviBIf0pMFMWuuvDNMAkoQFi-h0ZF",
        },
        {
          name: "Graph",
          link: "https://www.youtube.com/playlist?list=PLgUwDviBIf0oE3gA41TKO2H5bHpPd7fzn",
        },
        {
          name: "Leetcode",
          link: "https://www.leetcode.com",
        },
      ],
    },
    {
      icon: "coffee",
      id: "2",
      links: [
        {
          name: "Mango",
          link: "https://mangafire.to/",
        },
        {
          name: "G1",
          link: "https://g1prep.ca/content",
        },
        {
          name: "Internships",
          link: "https://github.com/SimplifyJobs/Summer2024-Internships",
        },
        {
          name: "Canadian",
          link: "https://github.com/jenndryden/Canadian-Tech-Internships-Summer-2024",
        },
      ],
    },
  ],
};

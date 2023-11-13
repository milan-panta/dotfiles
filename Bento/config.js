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
          name: "Usaco",
          link: "https://usaco.guide/general/intro-cp?lang=cpp",
        },
        {
          name: "Neetcode",
          link: "https://neetcode.io/roadmap",
        },
        {
          name: "Quercus",
          link: "https://q.utoronto.ca/",
        },
        {
          name: "Clash",
          link: "https://www.codingame.com/home",
        },
      ],
    },
    {
      icon: "github",
      id: "2",
      links: [
        {
          name: "PCRS",
          link: "https://pcrs.teach.cs.toronto.edu/csc209-2023-09/content/quests",
        },
        {
          name: "246",
          link: "https://ebookcentral-proquest-com.myaccess.library.utoronto.ca/lib/utoronto/reader.action?docID=5602529",
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
          name: "Usaco",
          link: "https://usaco.guide/general/intro-cp?lang=cpp",
        },
        {
          name: "Neetcode",
          link: "https://neetcode.io/roadmap",
        },
        {
          name: "Quercus",
          link: "https://q.utoronto.ca/",
        },
        {
          name: "Clash",
          link: "https://www.codingame.com/home",
        },
      ],
    },
    {
      icon: "coffee",
      id: "2",
      links: [
        {
          name: "PCRS",
          link: "https://pcrs.teach.cs.toronto.edu/csc209-2023-09/content/quests",
        },
        {
          name: "246",
          link: "https://ebookcentral-proquest-com.myaccess.library.utoronto.ca/lib/utoronto/reader.action?docID=5602529",
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

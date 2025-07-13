#let resume(
  author: "",
  author-position: left,
  personal-info-position: left,
  pronouns: "",
  location: "",
  email: "",
  github: "",
  linkedin: "",
  phone: "",
  personal-site: "",
  accent-color: "#000000",
  font: "New Computer Modern",
  paper: "us-letter",
  author-font-size: 20pt,
  font-size: 10pt,
  body,
) = {

  // Sets document metadata
  set document(author: author, title: author)

  // Document-wide formatting, including font and margins
  set text(
    // LaTeX style font
    font: font,
    size: font-size,
    lang: "en",
    // Disable ligatures so ATS systems do not get confused when parsing fonts.
    ligatures: false
  )

  // Reccomended to have 0.5in margin on all sides
  set page(
    margin: (0.5in),
    paper: paper,
  )

  // Link styles
  show link: underline


  // Small caps for section titles
  show heading.where(level: 2): it => [
    #pad(top: 0pt, bottom: -10pt, [#smallcaps(it.body)])
    #line(length: 100%, stroke: 1pt)
  ]

  // Accent Color Styling
  show heading: set text(
    fill: rgb(accent-color),
  )

  show link: set text(
    fill: rgb(accent-color),
  )

  // Name will be aligned left, bold and big
  show heading.where(level: 1): it => [
    #set align(author-position)
    #set text(
      weight: 700,
      size: author-font-size,
    )
    #pad(it.body)
  ]

  // Level 1 Heading
  [= #(author)]

  // Personal Info Helper
  let contact-item(value, prefix: "", link-type: "") = {
    if value != "" {
      if link-type != "" {
        link(link-type + value)[#(prefix + value)]
      } else {
        value
      }
    }
  }

  // Personal Info
  pad(
    top: 0.25em,
    align(personal-info-position)[
      #{
        let items = (
          contact-item(pronouns),
          contact-item(phone),
          contact-item(location),
          contact-item(email, link-type: "mailto:"),
          contact-item(github, link-type: "https://"),
          contact-item(linkedin, link-type: "https://"),
          contact-item(personal-site, link-type: "https://"),
        )
        items.filter(x => x != none).join("  |  ")
      }
    ],
  )

  // Main body.
  set par(justify: true)

  body
}

// Generic two by two component for resume
#let generic-two-by-two(
  top-left: "",
  top-right: "",
  bottom-left: "",
  bottom-right: "",
) = {
  [
    #top-left #h(1fr) #top-right \
    #bottom-left #h(1fr) #bottom-right
  ]
}

// Generic one by two component for resume
#let generic-one-by-two(
  left: "",
  right: "",
) = {
  [
    #left #h(1fr) #right
  ]
}

// Cannot just use normal --- ligature becuase ligatures are disabled for good reasons
#let dates-helper(
  start-date: "",
  end-date: "",
) = {
  start-date + " " + $dash.em$ + " " + end-date
}

// Section components below
#let edu(
  institution: "",
  dates: "",
  degree: "",
  gpa: "",
  location: "",
  // Makes dates on upper right like rest of components
  consistent: false,
) = {
  if consistent {
    // edu-constant style (dates top-right, location bottom-right)
    generic-two-by-two(
      top-left: strong(institution),
      top-right: dates,
      bottom-left: emph(degree),
      bottom-right: emph(location),
    )
  } else {
    // original edu style (location top-right, dates bottom-right)
    generic-two-by-two(
      top-left: strong(institution),
      top-right: location,
      bottom-left: emph(degree),
      bottom-right: emph(dates),
    )
  }
}

#let work(
  title: "",
  dates: "",
  company: "",
  location: "",
) = {
  generic-two-by-two(
    top-left: strong(title),
    top-right: dates,
    bottom-left: emph(company),
    bottom-right: emph(location),
  )
}

#let project(
  role: "",
  name: "",
  url: "",
  dates: "",
) = {
  generic-one-by-two(
    left: {
      if role == "" {
        [*#name* #if url != "" and dates != "" [ (#link("https://" + url)[#url])]]
      } else {
        [*#role*, #name #if url != "" and dates != ""  [ (#link("https://" + url)[#url])]]
      }
    },
    right: {
      if dates == "" and url != "" {
        link("https://" + url)[#url]
      } else {
        dates
      }
    },
  )
}

#let certificates(
  name: "",
  issuer: "",
  url: "",
  date: "",
) = {
  [
    *#name*, #emph(issuer)
    #if url != "" {
      [ (#link("https://" + url)[#url])]
    }
    #h(1fr) #date
  ]
}

#let extracurriculars(
  activity: "",
  dates: "",
) = {
  generic-one-by-two(
    left: strong(activity),
    right: dates,
  )
}

#show: resume.with(
  author: "Tomer Hanochi",
  location: "Kfar Saba, Israel",
  email: "contact@tomerhanochi.com",
  github: "github.com/tomerhanochi",
  phone: "054-549-4587",
  personal-site: "tomerhanochi.com",
  accent-color: "#26428b",
  font: "New Computer Modern",
  paper: "us-letter",
  author-position: center,
  personal-info-position: center,
)

== Profile
Passionate engineer with 4 years of hands-on experience in architecture,
development and maintenance of large scale on-prem & public cloud
native platforms and services. Expertise in various fields - CI-CD, GitOps,
containers and orchestration, automations, observability, identity
management, storage and networking.

Fast learner who loves his job, highly disciplined, team player, working
closely with dev teams and cyber researchers, strong problem solving
and debugging, rich presentation, teaching and guidance skiils.

== Work Experience

#work(
  title: "DevOps & Platform Engineer",
  location: "Rishon Lezion, Israel",
  company: "IDF - Matzov",
  dates: dates-helper(start-date: "Aug 2023", end-date: "Nov 2025"),
)
- Developed comprehensive Ansible automation suite including custom roles and modules for VM lifecycle management, multi-site HA DNS systems, global load balancers, and DHCP infrastructure, reducing manual deployment time by eliminating repetitive tasks.
- Architected and automated Splunk-as-a-Service platform delivering isolated, single-tenant SIEM clusters to external clients, enabling scalable security information and event management across distributed environments.
- Orchestrated automated deployment and GitOps management of 20+ OpenShift Container Platform clusters, ensuring consistent infrastructure provisioning and configuration management across enterprise environments
- Designed DNS naming conventions and routing strategies to support both active-active and active-passive application deployment patterns, facilitating flexible deployment architectures for development teams

#work(
  title: "Junior Software Engineer",
  location: "Tel Aviv, Israel",
  company: "Seemplicity Security",
  dates: dates-helper(start-date: "Jun 2021", end-date: "Feb 2023"),
)
- Developed microservice for automated vulnerability-to-team assignment using data-driven algorithms, enhancing security remediation workflows and reducing mean time to resolution.
- Created intelligent developer tooling script enabling selective microservice execution for local debugging, later integrated into CI/CD pipeline to support independent component testing and faster feedback loops.
- Built polyglot build system supporting multiple programming languages within monorepo architecture, streamlining development workflows and improving build consistency across diverse codebases.

== Achievements

#certificates(
  name: "Certificate of Excellence",
  issuer: "IDF - Matzov",
  date: "May 2025"
)
- Due to outstanding technical contributions and platform engineering achievements.

== Education

#edu(
  institution: "Rabin High School",
  location: "Kfar Saba, Israel",
  dates: dates-helper(start-date: "Sep 2019", end-date: "Jun 2022"),
  degree: "Specialized in Computer Science, Artificial Intelligence & Physics",
  consistent: true,
)
- Developed custom neural network trained via genetic algorithm in Python to autonomously play Tetris, creating both headless and GUI implementations that achieved continuous gameplay without failure, recognized as exemplary capstone project standard.

== Skills
- Programming - Python, Go, Rust
- Cloud - AWS ECS, S3, VPC
- Containerization - OCI, Docker, Kubernetes, OpenShift
- Databases - PostgreSQL, MySQL
- Version Control - Git, GitHub, GitLab
- CI/CD - GitHub Workflows, GitLab CI
- Observability - Prometheus, Grafana, OpenTelemtry, Elasticsearch
- Authentication/Authorization - SAML, OIDC, OAuth
- Infrastructure as Code - Terraform, Ansible, ArgoCD

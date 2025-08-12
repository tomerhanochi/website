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

#show: resume.with(
  author: "Tomer Hanochi",
  email: "contact@tomerhanochi.com",
  github: "github.com/tomerhanochi",
  phone: "(+972) 54-549-4587",
  linkedin: "linkedin.com/in/tomer-hanochi",
  accent-color: "#26428b",
  font: "New Computer Modern",
  paper: "us-letter",
  author-position: center,
  personal-info-position: center,
)

== Profile
Software Engineer with 4+ years of experience building scalable backend systems and cloud-native applications. Proficient in Python, Go, and Rust with hands-on experience developing microservices, automating infrastructure, and implementing CI/CD pipelines.

Strong background in cloud platforms (AWS), containerization (Docker, Kubernetes), and database design. Passionate about writing clean, efficient code and collaborating with cross-functional teams to deliver reliable software solutions.

== Work Experience
#work(
  title: "DevOps & Platform Engineer",
  location: "Rishon Lezion, Israel",
  company: "IDF - Matzov",
  dates: dates-helper(start-date: "Aug 2023", end-date: "Nov 2025"),
)
- Developed custom Python Ansible modules and plugins to enable fully end-to-end automated infrastructure provisioning.
- Deployed and maintained 20+ OpenShift & K8S clusters, using GitOps principles with ArgoCD.
- Architected Splunk-as-a-Service platform delivering isolated multi-site and highly available clusters to numerous external clients.
- Designed DNS naming conventions and routing strategies supporting multi-site active-active and active-passive deployment patterns.

#work(
  title: "Junior Software Engineer",
  location: "Tel Aviv, Israel",
  company: "Seemplicity Security",
  dates: dates-helper(start-date: "Jun 2021", end-date: "Feb 2023"),
)
- Developed Python-based backend services and APIs on cloud platforms, implementing distributed system components for high-scale production environments.
- Created internal developer tooling enabling selective microservice execution for local debugging, later integrated into CI/CD pipeline for automated end to end tests.
- Implemented Infrastructure as Code using Terraform and Python automation, standardizing deployment processes across multiple environments.

== Achievements
#certificates(
  name: "Certificate of Excellence",
  issuer: "IDF - Matzov",
  date: "May 2025"
)
- Due to outstanding technical contributions and platform engineering achievements.

== Projects
#project(
  name: "libsubid",
  url: "github.com/tomerhanochi/libsubid"
)

Built Rust-based dynamic library to automatically assign subuid/subgid ranges to non-root users, solving manual subuid/subgid assignment for rootless containerized environments.

#project(
  name: "pytris",
  url: "github.com/tomerhanochi/pytris"
)

Developed custom neural network trained via genetic algorithm in Python to autonomously play Tetris, creating headless and GUI implementations that achieved continuous gameplay without failure.

== Skills
- Programming - Python, Go, Rust, Bash
- Cloud - AWS ECS, S3, Lambda
- Backend Development - REST, gRPC, Microservices Architecture
- Systems & Networking - Linux, TCP/UDP, DNS, HTTP/HTTPS
- Databases - PostgreSQL, MySQL, Redis
- Containerization - OCI, Docker, Kubernetes, OpenShift
- Version Control & CI/CD - Git, GitHub Workflows, GitLab CI
- Observability - Prometheus, Grafana, OpenTelemetry, Elasticsearch
- Authentication/Authorization - SAML, OIDC, OAuth

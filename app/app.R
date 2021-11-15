# Purpose - creating a data explorer for the NBER abstract data

library(shiny)
library(tidyverse)
library(tidyquant)
library(bslib)
library(thematic)
library(glue)
library(DT)
thematic_shiny()
theme_set(theme_light())
theme_update(text = element_text(size = 17))


# data
df <- read_rds("abstracts_df.rds")

ui <- fluidPage(
    theme = bs_theme(bootswatch = "pulse", font_scale = 1.2),
    titlePanel("NBER working paper term frequency explorer"),
    sidebarLayout(
        sidebarPanel(
            fluidRow(column(
                width = 12,
                p("This explorer shows how often different terms appear in NBER wp abstracts. Filtered papers are linked in the table below."),
                br(),
                p("Enter your terms, separated by a comma:")
            ),
            textInput(width = "100%",
                      "input_terms",
                      "",
                      value = "Growth, Climate, Unemployment"),
            sliderInput(width = "100%",
                        "smoother",
                        "Smoothing factor:",
                        min = 1,
                        max = 5,
                        value = 2
            ),
            column(
                width = 12,
                br(),
                a(href = "https://github.com/j-jayes/NBER-methods", "My GitHub Repo", target = "_blank"),
                br(),
                a(href = "https://github.com/bldavies/nberwp", "Ben Davies' nberwp package", target = "_blank"),
                br())
            )


        ),
        mainPanel(
            plotOutput("term_freq"),
            dataTableOutput("paper_table")
        )
    )
)

server <- function(input, output) {

    output$term_freq <- renderPlot({
        req(input$input_terms)
        nber_term_freq_plot(nber_term_freq_df())

    })

    output$paper_table <- renderDataTable({

        b1 <- input$input_terms %>% as.data.frame() %>%  str_split(",")

        b2 <- b1[[1]] %>% str_squish() %>% paste(sep = "|")

        template <- '<a href="{ url }">{ title }</a>'

        df %>% filter(str_detect(abstract, b2)) %>%
            mutate(url = str_c("https://www.nber.org/papers/", paper),
                   link = glue(template)) %>%
            select(link, year) %>%
            arrange(desc(year)) %>%
            datatable(., escape = FALSE,
                      rownames = F,
                      colnames = c("Paper link", "Year"),
                      options = list(pageLength = 5, dom = "tip"))

    })

    nber_term_freq_df <- reactive({
        a1 <- input$input_terms %>% as.data.frame() %>%  str_split(",")

        a2 <- a1[[1]] %>% str_squish() %>% paste(sep = ", ")

        get_term_freq_df(a2, input$smoother)})

    get_term_freq_df <- function(terms, smoother) {
        get_term_share <- function(method) {
            df %>%
                mutate(
                    time_lump = year - year %% {{ smoother }},
                    abstract = str_to_lower(abstract)
                ) %>%
                count(time_lump, rd = str_detect(abstract, method)) %>%
                pivot_wider(names_from = rd, values_from = n, values_fill = 0) %>%
                mutate(share = `TRUE` / (`FALSE` + `TRUE`)) %>%
                select(time_lump, share)
        }

        terms_df <- terms %>%
            as_tibble() %>%
            rename(method = value) %>%
            mutate(
                method = str_to_lower(method),
                share = map(method, possibly(get_term_share, tibble("Waiting for input")))
            ) %>%
            unnest(share) %>%
            mutate(method = str_to_title(method))


    }


    nber_term_freq_plot <- function(tbl){

    terms_df_labs <- tbl %>%
        filter(time_lump == max(time_lump))

    n_terms <- tbl %>%
        distinct(method) %>%
        count() %>% pull()

    n_rows <- round((n_terms + 0) / 3)

    tbl %>%
        ggplot(aes(time_lump, share, colour = method)) +
        geom_point() +
        geom_line(cex = 1) +
        geom_text(aes(label = method),
                  data = terms_df_labs %>%
                      filter(time_lump == max(time_lump)),
                  hjust = -.1,
                  show.legend = F,
                  check_overlap = T
        ) +
        expand_limits(x = 2030) +
        scale_y_continuous(labels = scales::percent_format()) +
        scale_colour_tq(theme = "dark") +
        labs(
            x = "Year of most recent revision as NBER wp",
            colour = NULL,
            y = NULL,
            title = "Percentage of NBER working papers with term in abstract"
        ) +
        theme(legend.position = "bottom") +
        guides(colour = guide_legend(nrow = n_rows, byrow = TRUE))

    }
}

shinyApp(ui = ui, server = server)

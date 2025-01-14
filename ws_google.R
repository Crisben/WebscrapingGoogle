
# Webscrpaing Google with R -----------------------------------------------
# With this code the objective is to obtain the RUC of some enterprises in Ecuador, we can use the oficial web page SRI in Ecuador to do it, but in some cases we can have different names, or with some small changes, so, the idea is to use google and get some insgihts and then use that result to continue mining and reduce manual work.

library(XML)
library(stringr)
library(rvest)

raz <- data.frame("raz" = c('AWA-NUTRITION S.A.',
                  'BUSTAMANTE HOLGUIN MARIA DEL CARMEN ',
                  'CEREALES ANDINOS CERANDINA CIA. LTDA.',
                  'Compañía Ecuatoriana del Té C. A.',
                  'JUMANDIPRO S.A ',
                  'UNIVFOOD S.A',
                  'LA LEYENDA DEL CHOCOLATE CHOCOLEYENDA CIA. LTDA. ',
                  'GOURMETANDINO S.A.S. B.I.C.',
                  'GENEROS ECUATORIANOS ECUAGENERA CIA. LTDA. ',
                  'FUNDACION CHANKUAP RECURSOS PARA EL FUTURO '
))
raz$ruc <- ""

# browser config
rD <- RSelenium::rsDriver(port = sample(49152:65535, 1),#port = 43170L,
                          browser = c("firefox"), chromever = NULL)

remDr <- rD[["client"]]

url <- "https://www.google.com/webhp?hl=es-419&sa=X&ved=0ahUKEwj9neWSkZ2GAxVaTTABHbCuA2MQPAgJ"

# process
for(j in 1:length(raz$raz)){
        remDr$navigate(url)
        Sys.sleep(1)
        
        busq <- remDr$findElement(using = "xpath", paste0('//*[@id="APjFqb"]'))
        busq$clickElement()
        
        busq$sendKeysToElement(list(raz$raz[j], key = "enter"))
        Sys.sleep(2)
        
        # Obtener la página de resultados
        page_source <- remDr$getPageSource()[[1]]
        doc <- read_html(page_source)
        
        # Extraer los resultados de búsqueda
        titulos <- doc %>%
                html_nodes('.g') %>%  # Seleccionar nodos con clase 'g', que contienen resultados
                html_nodes('h3') %>%  # Seleccionar títulos de los resultados
                html_text()
        
        detalle <- doc %>%
                html_nodes('.g') %>%  # Seleccionar nodos con clase 'g', que contienen resultados
                # html_nodes('h3') %>%  # Seleccionar títulos de los resultados
                html_text()
        
        # Crear un data frame con los resultados
        detalle <- data.frame(detalle = detalle, stringsAsFactors = FALSE)
        
        # Utiliza grep para encontrar las cadenas de 13 dígitos que terminan en '001'
        pattern <- "\\d{10}001"
        
        tmp <- list(0)
        
        for(i in 1:nrow(detalle)){
                text <- detalle$detalle[i]
                extracted_strings <- unique(unlist(str_extract_all(text, pattern)))[1]
                
                print(extracted_strings)
                tmp[i] <- extracted_strings
        }
        
        raz$ruc[j] <- unique(sort(unlist(tmp)))[1]
        
        print(raz$ruc[j])
        print(j)
}


remDr$close()
rD$server$stop()

# export
writexl::write_xlsx(raz, "resultados.xlsx")



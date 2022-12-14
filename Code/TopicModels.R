
library("tm")

# READING DATA AND PRE-PROCESS AWAY "WEIRD" ARTICLES - DON'T WORRY IF YOU CAN'T FOLLOW THIS PART

# Reading text from articles in Journal of Statistical Software using a special reader function.
#install.packages("corpus.JSS.papers", repos = "http://datacube.wu.ac.at/", type = "source")
data("JSS_papers", package = "corpus.JSS.papers")

# Extract only papers up to 2010-08-05 and remove papers with weird (non-ASCII characters) in abstract
# Note the Encoding function returns "unknown" for ASCII text.
JSS_papers <- JSS_papers[JSS_papers[,"date"] < "2010-08-05",]
JSS_papers <- JSS_papers[sapply(JSS_papers[, "description"], Encoding) == "unknown",]

# Removing HTML markup for subscripting and greek letters etc for reading to corpus
#install.packages("XML")
library("XML")
remove_HTML_markup <- function(s) tryCatch({ doc <- htmlTreeParse(paste("<!DOCTYPE html>", s), asText = TRUE, trim = FALSE)
                                             xmlValue(xmlRoot(doc))}, error = function(s) s)
corpus <- Corpus(VectorSource(sapply(JSS_papers[, "description"], remove_HTML_markup)))


# Construct DocumentTerm matrix
# Using some linguistic pre-processing (stemming, remove stopwords and punctuation etc)
# install.packages("SnowballC")
library(SnowballC)
Sys.setlocale("LC_COLLATE", "C") # Language setting for the linguistic analysis
JSS_dtm <- DocumentTermMatrix(corpus, control = list(stemming = TRUE, stopwords = TRUE, 
                             minWordLength = 3, removeNumbers = TRUE, removePunctuation = TRUE))
JSS_dtm


# Reducing the number of features by keeping only words with tf-idf > 0.1
#install.packages("slam")
library("slam")
term_tfidf <- tapply(JSS_dtm$v/row_sums(JSS_dtm)[JSS_dtm$i], JSS_dtm$j, mean) * log2(nDocs(JSS_dtm)/col_sums(JSS_dtm > 0))
JSS_dtm <- JSS_dtm[,term_tfidf >= 0.1] # Removing words with low tf-idf
JSS_dtm <- JSS_dtm[row_sums(JSS_dtm) > 0,] # Removing documents where no feature is present.

# Fitting a topic model with 30 topics
#install.packages("topicmodels")
library(topicmodels)
LDAfit <- LDA(JSS_dtm[1:340,], k = 10, control = list(seed = 2010)) 
mostLikelyWords <- terms(LDAfit, 10)
mostLikelyWords
mostLikelyTopics <- topics(LDAfit, 2)
mostLikelyTopics

# Predicting the last three document in the corpus (which was left out in the estimation/training)
postNewData <- posterior(LDAfit, newdata = JSS_dtm[340:342,])
postNewData$topics
terms(LDAfit, 10)[,c(7,9)] # Document 341 talks mainly about topic 7 and 9
corpus[340][[1]]$content



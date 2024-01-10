

testnames <- list.files(here::here("arachne-ee"))

for (i in seq_along(testnames)) {
  message(paste("writing ", testnames[i]))
  withr::with_dir(here::here("arachne-ee"), {
    filenames <- list.files(testnames[i], full.names = T)
    zip(zipfile = paste0("../arachne-ee-zip/", testnames[i]), files = filenames)
  })
}




testnames <- list.files(here::here("darwin-ee"))

for (i in seq_along(testnames)) {
  message(paste("writing ", testnames[i]))
  withr::with_dir(here::here("arachne-ee"), {
    filenames <- list.files(testnames[i], full.names = T)
    zip(zipfile = paste0("../darwin-ee-zip/", testnames[i]), files = filenames)
  })
}

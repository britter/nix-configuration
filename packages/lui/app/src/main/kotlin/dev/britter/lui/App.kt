package dev.britter.lui

class App {
  val message: String
  get() {
    return "Hello world!"
  }
}

fun main() {
  println(App().message)
}

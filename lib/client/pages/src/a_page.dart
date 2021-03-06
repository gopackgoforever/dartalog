part of pages;



abstract class APage<T extends APage> extends AControl {
  APage.created(this.title) : super.created();

  @Property(notify: true)
  String title;

  bool showBackButton = false;

  int lastScrollPosition = 0;

  Future activate(DartalogApi api, Map args) async {
    await super.activate(api, args);
  }


  void setTitle(String newTitle) {
    this.title = newTitle;
    set("title", newTitle);
    mainApp.evaluatePage();
  }

  Future goBack() {

  }

  bool evaluate(APage page, bool evaluate(T page)) {
    if(page is T) {
      return evaluate(page);
    }
    return false;
  }
}
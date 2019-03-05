import 'package:flutter/material.dart';

import '../search_data_source.dart';
import '../shared_constant.dart';
import 'no_result_card.dart';
import 'web_search_result_card.dart';

@immutable
class SearchResultPage extends StatefulWidget {
  final SearchDataSource dataSource;
  final SearchType searchType;
  final SearchResults initialSearchResult;
  final SearchQuery searchQuery;
  final Refinement currentRefinement;
  final bool withRefinementTabBar;

  SearchResultPage(this.dataSource, this.searchType, this.initialSearchResult,
      this.searchQuery,
      {this.currentRefinement, this.withRefinementTabBar = true});

  @override
  _SearchResultPageState createState() =>
      new _SearchResultPageState(initialSearchResult);
}

class _SearchResultPageState extends State<SearchResultPage>
    with SingleTickerProviderStateMixin {
  SearchResults initialSearchResult;
  SearchResults currentSearchResults;
  TabController _tabController;
  List<Tab> _refinementTabs = new List<Tab>();

  _SearchResultPageState(this.initialSearchResult) {
    if (initialSearchResult.refinements.isNotEmpty) {
      _refinementTabs.add(Tab(text: 'all'));
      initialSearchResult.refinements.forEach(
              (refinement) => _refinementTabs.add(Tab(text: refinement.label)));
      _tabController =
          TabController(vsync: this, length: _refinementTabs.length);
    }
  }

  @override
  void dispose() {
    currentSearchResults = null;
    this._refinementTabs.clear();
    _tabController?.dispose();
    super.dispose();
  }

  Widget _buildWebSearchResultSubList(SearchResults searchResults) {
    return ListView(
        shrinkWrap: true,
        primary: false,
        children: searchResults.searchResults.map((searchResult) {
          return WebSearchResultCard(searchResult: searchResult);
        }).toList());
  }

  Widget _buildWebListPage(BuildContext context) {
    return ListView.builder(
        itemCount:
            10, // Custom Search API will not return more than 100 results.
        itemBuilder: (BuildContext context, int index) {
          print('$index');
          if (index == 0) {
            this.currentSearchResults = initialSearchResult;
            if (currentSearchResults.searchResults.isEmpty) {
              return GridView.count(
                crossAxisCount: 1,
                mainAxisSpacing: 4.0,
                crossAxisSpacing: 4.0,
                padding: const EdgeInsets.all(4.0),
                children: [new NoResultCard()],
              );
            }
            return _buildWebSearchResultSubList(initialSearchResult);
          }
          if (currentSearchResults.nextPage != null) {
            return FutureBuilder(
              future: widget.dataSource.search(currentSearchResults.nextPage),
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.none:
                    return Text('Press button to start.');
                  case ConnectionState.active:
                  case ConnectionState.waiting:
                    return SizedBox(
                      height: MediaQuery.of(context).size.height * 2,
                      child: Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: EdgeInsets.only(top: 5.0),
                            child: CircularProgressIndicator(),
                          )),
                    );
                  case ConnectionState.done:
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }
                    this.currentSearchResults = snapshot.data;
                    if (currentSearchResults.searchResults.isEmpty) {
                      return GridView.count(
                        crossAxisCount: 1,
                        mainAxisSpacing: 4.0,
                        crossAxisSpacing: 4.0,
                        padding: const EdgeInsets.all(4.0),
                        children: [new NoResultCard()],
                      );
                    }
                    return _buildWebSearchResultSubList(snapshot.data);
                }
              },
            );
          } else {
            return Container(width: 0.0, height: 0.0);
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.searchType) {
      case SearchType.image:
        return Text('not implemented');
      case SearchType.web:
        if (this._refinementTabs.isEmpty || !widget.withRefinementTabBar) {
          return _buildWebListPage(context);
        }
        if (widget.withRefinementTabBar) {
          return Scaffold(
              appBar: new PreferredSize(
                preferredSize: Size.fromHeight(kToolbarHeight),
                child: new Container(
                  color: Colors.blue,
                  child: new SafeArea(
                    child: Column(
                      children: <Widget>[
                        new TabBar(
                          isScrollable: true,
                          controller: _tabController,
                          tabs: _refinementTabs,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              body: TabBarView(
                controller: _tabController,
                children: _refinementTabs.map((Tab tab) {
                  if (tab.text == 'all') {
                    return _buildWebListPage(context);
                  } else {
                    final currentRefinement = initialSearchResult.refinements
                        .firstWhere((element) => element.label == tab.text);
                    final query = widget.searchQuery.q +
                        " " +
                        currentRefinement.labelWithOp;
                    print(query);
                    return FutureBuilder(
                      future: widget.dataSource
                          .search(widget.searchQuery.copyWith(q: query)),
                      builder: (context, snapshot) {
                        switch (snapshot.connectionState) {
                          case ConnectionState.none:
                            return Text('Press button to start.');
                          case ConnectionState.active:
                          case ConnectionState.waiting:
                            return SizedBox(
                              height: MediaQuery
                                  .of(context)
                                  .size
                                  .height * 2,
                              child: Align(
                                  alignment: Alignment.topCenter,
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 5.0),
                                    child: CircularProgressIndicator(),
                                  )),
                            );
                          case ConnectionState.done:
                            if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            }
                            if (snapshot.data.searchResults.isEmpty) {
                              return GridView.count(
                                crossAxisCount: 1,
                                mainAxisSpacing: 4.0,
                                crossAxisSpacing: 4.0,
                                padding: const EdgeInsets.all(4.0),
                                children: [new NoResultCard()],
                              );
                            }
                            return SearchResultPage(
                              widget.dataSource,
                              widget.searchType,
                              snapshot.data,
                              widget.searchQuery,
                              currentRefinement: currentRefinement,
                              withRefinementTabBar: false,
                            );
                        }
                      },
                    );
                  }
                }).toList(),
              ));
        }
    }
  }
}

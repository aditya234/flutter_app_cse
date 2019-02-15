import 'package:meta/meta.dart';
import 'dart:async';
import 'dart:convert';
import 'package:expire_cache/expire_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import "package:googleapis_auth/auth_io.dart" as auth;
import 'package:googleapis/customsearch/v1.dart' as customsearch;
import 'package:english_words/english_words.dart';

/// A wrapper class for [customsearch.Result].
/// [SearchResult] will use the landing page link to measure if two results are
/// the same. This is useful to deduplicate image search result.
class SearchResult {
  final customsearch.Result result;

  SearchResult(this.result);

  SearchResult.escapeLineBreakInSnippet(this.result) {
    this.result.snippet = this.result.snippet.replaceAll("\n", "");
  }

  @override
  String toString() {
    return 'title:${this.result.title}\nsnippet:${this.result.snippet}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    // Use landing page link to see if two results are the same.
    if (this.result.image != null) {
      return other is SearchResult &&
          runtimeType == other.runtimeType &&
          result.image.contextLink == other.result.image.contextLink;
    } else {
      return other is SearchResult &&
          runtimeType == other.runtimeType &&
          result.link == other.result.link;
    }
  }

  @override
  int get hashCode => result.image == null
      ? result.link.hashCode
      : result.image.contextLink.hashCode;
}

class Promotion {
  final customsearch.Promotion promotion;

  Promotion(this.promotion);
}

/// A wrapper class to aggregate all the search result fields that we need.
///
/// And deduplicate results.
class SearchResults {
  List<SearchResult> searchResults = List<SearchResult>();
  List<Promotion> promotions = List<Promotion>();
  SearchQuery nextPage;

  SearchResults.empty();

  SearchResults(customsearch.Search search) {
    var results = new List<SearchResult>();
    search.items.forEach(
        (item) => results.add(SearchResult.escapeLineBreakInSnippet(item)));
    // Deduplicate search result.
    this.searchResults = Set<SearchResult>.from(results).toList();
  }
}

/// A wrapper class for search request, to make caching search request possible.

@immutable
class SearchQuery {
  String q;
  String c2coff;
  String cr;
  String cx;
  String dateRestrict;
  String exactTerms;
  String excludeTerms;
  String fileType;
  String filter;
  String gl;
  String googlehost;
  String highRange;
  String hl;
  String hq;
  String imgColorType;
  String imgDominantColor;
  String imgSize;
  String imgType;
  String linkSite;
  String lowRange;
  String lr;
  int num;
  String orTerms;
  String relatedSite;
  String rights;
  String safe;
  String searchType;
  String siteSearch;
  String siteSearchFilter;
  String sort;
  int start;

  /// Used to get partial response, see:
  /// https://developers.google.com/custom-search/v1/performance#partial
  String fields;

  SearchQuery(this.q, this.cx,
      {this.c2coff,
      this.cr,
      this.dateRestrict,
      this.exactTerms,
      this.excludeTerms,
      this.fileType,
      this.filter,
      this.gl,
      this.googlehost,
      this.highRange,
      this.hl,
      this.hq,
      this.imgColorType,
      this.imgDominantColor,
      this.imgSize,
      this.imgType,
      this.linkSite,
      this.lowRange,
      this.lr,
      this.num,
      this.orTerms,
      this.relatedSite,
      this.rights,
      this.safe,
      this.searchType,
      this.siteSearch,
      this.siteSearchFilter,
      this.sort,
      this.start,
      this.fields});

  /// Run custom search on this [SearchQuery].
  Future<SearchResults> runSearch(customsearch.CustomsearchApi api) async {
    var search = await api.cse.list(q, cx: cx, searchType: this.searchType);
    var result = SearchResults(search);
    if (search.queries['nextPage'] != null) {
      result.nextPage = this
          .copyWith(start: search.queries['nextPage'][0].startIndex);
    }
    return result;
  }

  @override
  String toString() {
    return 'SearchQuery{q: $q, c2coff: $c2coff, cr: $cr, cx: $cx, dateRestrict: $dateRestrict, exactTerms: $exactTerms, excludeTerms: $excludeTerms, fileType: $fileType, filter: $filter, gl: $gl, googlehost: $googlehost, highRange: $highRange, hl: $hl, hq: $hq, imgColorType: $imgColorType, imgDominantColor: $imgDominantColor, imgSize: $imgSize, imgType: $imgType, linkSite: $linkSite, lowRange: $lowRange, lr: $lr, num: $num, orTerms: $orTerms, relatedSite: $relatedSite, rights: $rights, safe: $safe, searchType: $searchType, siteSearch: $siteSearch, siteSearchFilter: $siteSearchFilter, sort: $sort, start: $start, fields: $fields}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchQuery &&
          runtimeType == other.runtimeType &&
          q == other.q &&
          c2coff == other.c2coff &&
          cr == other.cr &&
          cx == other.cx &&
          dateRestrict == other.dateRestrict &&
          exactTerms == other.exactTerms &&
          excludeTerms == other.excludeTerms &&
          fileType == other.fileType &&
          filter == other.filter &&
          gl == other.gl &&
          googlehost == other.googlehost &&
          highRange == other.highRange &&
          hl == other.hl &&
          hq == other.hq &&
          imgColorType == other.imgColorType &&
          imgDominantColor == other.imgDominantColor &&
          imgSize == other.imgSize &&
          imgType == other.imgType &&
          linkSite == other.linkSite &&
          lowRange == other.lowRange &&
          lr == other.lr &&
          num == other.num &&
          orTerms == other.orTerms &&
          relatedSite == other.relatedSite &&
          rights == other.rights &&
          safe == other.safe &&
          searchType == other.searchType &&
          siteSearch == other.siteSearch &&
          siteSearchFilter == other.siteSearchFilter &&
          sort == other.sort &&
          start == other.start &&
          fields == other.fields;

  @override
  int get hashCode =>
      q.hashCode ^
      c2coff.hashCode ^
      cr.hashCode ^
      cx.hashCode ^
      dateRestrict.hashCode ^
      exactTerms.hashCode ^
      excludeTerms.hashCode ^
      fileType.hashCode ^
      filter.hashCode ^
      gl.hashCode ^
      googlehost.hashCode ^
      highRange.hashCode ^
      hl.hashCode ^
      hq.hashCode ^
      imgColorType.hashCode ^
      imgDominantColor.hashCode ^
      imgSize.hashCode ^
      imgType.hashCode ^
      linkSite.hashCode ^
      lowRange.hashCode ^
      lr.hashCode ^
      num.hashCode ^
      orTerms.hashCode ^
      relatedSite.hashCode ^
      rights.hashCode ^
      safe.hashCode ^
      searchType.hashCode ^
      siteSearch.hashCode ^
      siteSearchFilter.hashCode ^
      sort.hashCode ^
      start.hashCode ^
      fields.hashCode;

  SearchQuery copyWith(
      {String q,
      String cx,
      String c2coff,
      String cr,
      String dateRestrict,
      String exactTerms,
      String excludeTerms,
      String fileType,
      String filter,
      String gl,
      String googlehost,
      String highRange,
      String hl,
      String hq,
      String imgColorType,
      String imgDominantColor,
      String imgSize,
      String imgType,
      String linkSite,
      String lowRange,
      String lr,
      int num,
      String orTerms,
      String relatedSite,
      String rights,
      String safe,
      String searchType,
      String siteSearch,
      String siteSearchFilter,
      String sort,
      int start,
      String fields}) {
    return SearchQuery(q ?? this.q, cx ?? this.cx,
        c2coff: c2coff ?? this.c2coff,
        cr: cr ?? this.cr,
        dateRestrict: dateRestrict ?? this.dateRestrict,
        exactTerms: exactTerms ?? this.exactTerms,
        excludeTerms: excludeTerms ?? this.excludeTerms,
        fileType: fileType ?? this.fileType,
        filter: filter ?? this.filter,
        gl: gl ?? this.gl,
        googlehost: googlehost ?? this.googlehost,
        highRange: highRange ?? this.highRange,
        hl: hl ?? this.hl,
        hq: hq ?? this.hq,
        imgColorType: imgColorType ?? this.imgColorType,
        imgDominantColor: imgDominantColor ?? this.imgDominantColor,
        imgSize: imgSize ?? this.imgSize,
        imgType: imgType ?? this.imgType,
        linkSite: linkSite ?? this.linkSite,
        lowRange: lowRange ?? this.lowRange,
        lr: lr ?? this.lr,
        num: num ?? this.num,
        orTerms: orTerms ?? this.orTerms,
        relatedSite: relatedSite ?? this.relatedSite,
        rights: rights ?? this.rights,
        safe: safe ?? this.safe,
        searchType: searchType ?? this.searchType,
        siteSearch: siteSearch ?? this.siteSearch,
        siteSearchFilter: siteSearchFilter ?? this.siteSearchFilter,
        sort: sort ?? this.sort,
        start: start ?? this.start,
        fields: fields ?? this.fields);
  }
}

/// Abstract class for Search Data Source.
abstract class SearchDataSource {
  String cx;

  /// Use an existing searchQuery to search.
  Future<SearchResults> search(SearchQuery searchQuery);
}

class _StaticSearchResponse {
  final String assetPath;
  final String searchType;
  String searchResponseJsonString;

  _StaticSearchResponse(
      {this.assetPath, this.searchType, this.searchResponseJsonString});
}

/// A fake search data source, that reads data from flutter assests.
///
/// Choose to do the caching in this class, rather than in the
/// [SearchDelegate.showResults]. Because this is controllable by developer,
/// we don't know if the implementation detail about [SearchDelegate] will
/// change or not.
class FakeSearchDataSource implements SearchDataSource {
  final Map<String, _StaticSearchResponse> searchResponses = {
    'web': _StaticSearchResponse(
        assetPath: 'res/sampledata/nytimes_sample_data.json'),
    'image': _StaticSearchResponse(
        assetPath: 'res/sampledata/nytimes_image_sample_data.json',
        searchType: 'image'),
    'promotion': _StaticSearchResponse(
        assetPath: 'res/sampledata/nytimes_with_promotion.json'),
  };
  final ExpireCache<SearchQuery, SearchResults> _cache =
      ExpireCache<SearchQuery, SearchResults>();

  @override
  String cx = 'fake_cx';

  FakeSearchDataSource() {
    searchResponses.keys.forEach((key) {
      loadAssetToSearchResponse(key, searchResponses[key].assetPath);
    });
  }

  void loadAssetToSearchResponse(String searchKey, String assetPath) async {
    searchResponses[searchKey].searchResponseJsonString =
        await rootBundle.loadString(assetPath);
  }

  @override
  Future<SearchResults> search(final SearchQuery searchQuery) async {
    if (!searchResponses.containsKey(searchQuery.q)) {
      return SearchResults.empty();
    }
    if (searchResponses[searchQuery.q].searchType != searchQuery.searchType) {
      return SearchResults.empty();
    }
    if (!_cache.isKeyInFlightOrInCache(searchQuery)) {
      _cache.markAsInFlight(searchQuery);
    } else {
      return await _cache.get(searchQuery);
    }
    Map searchMap =
        jsonDecode(searchResponses[searchQuery.q].searchResponseJsonString);
    customsearch.Search search = customsearch.Search.fromJson(searchMap);

    var result = SearchResults(search);
    if (search.queries['nextPage'] != null) {
      result.nextPage = searchQuery.copyWith(
          start: search.queries['nextPage'][0].startIndex);
    }
    _cache.set(searchQuery, result);
    return result;
  }
}

/// The search data source that uses Custom Search API.
///
/// Choose to do the caching in this class, rather than in the
/// [SearchDelegate.showResults]. Because this is controllable by developer,
/// we don't know if the implementation detail about [SearchDelegate] will
/// change or not.
class CustomSearchDataSource implements SearchDataSource {
  final String apiKey;
  customsearch.CustomsearchApi api;
  final ExpireCache<SearchQuery, SearchResults> _cache =
      ExpireCache<SearchQuery, SearchResults>();

  CustomSearchDataSource({@required this.cx, @required this.apiKey}) {
    var client = auth.clientViaApiKey(apiKey);
    this.api = new customsearch.CustomsearchApi(client);
  }

  @override
  String cx;

  @override
  Future<SearchResults> search(final SearchQuery searchQuery) async {
    if (searchQuery.q.isEmpty) {
      return SearchResults.empty();
    }
    if (!_cache.isKeyInFlightOrInCache(searchQuery)) {
      _cache.markAsInFlight(searchQuery);
    } else {
      return await _cache.get(searchQuery);
    }

    final result = await searchQuery.runSearch(this.api);
    _cache.set(searchQuery, result);
    return result;
  }
}

abstract class AutoCompleteDataSource {
  List<String> getAutoCompletions({String query, int resultNumber});
}

class CommonEnglishWordAutoCompleteDataSource
    implements AutoCompleteDataSource {
  const CommonEnglishWordAutoCompleteDataSource();

  @override
  List<String> getAutoCompletions({String query, int resultNumber = 10}) {
    var results = all.where((String word) => word.startsWith(query)).toList();
    return results.length > resultNumber
        ? results.sublist(0, resultNumber)
        : results;
  }
}

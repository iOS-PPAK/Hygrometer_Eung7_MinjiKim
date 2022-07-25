//
//  PresentViewController.swift
//  Hygrometer
//
//  Created by 김민지 on 2022/07/10.
//

import UIKit

class PresentViewController: UIViewController {

  private lazy var topFadeView: UIView = {
    let view = UIView()

    return view
  }()

  private lazy var containerView: UIView = {
    let view = UIView()
    view.backgroundColor = .white
    view.layer.cornerRadius = 40
    view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    view.layer.masksToBounds = true

    return view
  }()

  private lazy var closeButton: UIButton = {
    let button = UIButton()
    button.setImage(UIImage(systemName: "xmark"), for: .normal)
    button.tintColor = .black
    button.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)

    return button
  }()

  private lazy var searchBar: UISearchBar = {
    let searchBar = UISearchBar()
    searchBar.searchBarStyle = .minimal
    searchBar.placeholder = "지역 검색"
    searchBar.delegate = self

    return searchBar
  }()

  private lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.text = "Bookmark"
    label.font = .systemFont(ofSize: 20, weight: .regular)
    label.textAlignment = .center

    return label
  }()

  private lazy var tableView: UITableView = {
    let tableView = UITableView()
    tableView.separatorStyle = .none
    tableView.backgroundColor = .clear
    tableView.showsVerticalScrollIndicator = false
    tableView.keyboardDismissMode = .onDrag
    tableView.dataSource = self
    tableView.delegate = self
    tableView.register(PresentTableViewCell.self, forCellReuseIdentifier: PresentTableViewCell.identifier)

    return tableView
  }()

  private lazy var emptyLabel: UILabel = {
    let label = UILabel()
    label.textAlignment = .center
    label.textColor = .gray
    label.font = .systemFont(ofSize: 16, weight: .regular)

    return label
  }()

  private var sceneType: SceneType

  private var regionList: [Location] = []

  private var keyword = ""
  private var currentPage: Int = 1
  private let display: Int = 10
  var dismissCompletion: () -> Void = {}

  init(sceneType: SceneType) {
    self.sceneType = sceneType
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    applySceneType()
    setGesture()
  }

  private func setupUI() {
    view.backgroundColor = .clear

    [topFadeView, containerView].forEach {
      view.addSubview($0)
    }

    topFadeView.snp.makeConstraints { make in
      make.height.equalTo(50)
      make.top.leading.trailing.equalToSuperview()
    }

    containerView.snp.makeConstraints { make in
      make.top.equalTo(topFadeView.snp.bottom)
      make.leading.trailing.bottom.equalToSuperview()
    }

    [closeButton, searchBar, titleLabel, emptyLabel, tableView].forEach {
      containerView.addSubview($0)
    }

    let inset: CGFloat = 8

    closeButton.snp.makeConstraints { make in
      make.width.height.equalTo(50)
      make.top.trailing.equalToSuperview().inset(inset)
    }

    [searchBar, titleLabel].forEach {
      $0.snp.makeConstraints { make in
        make.top.equalTo(closeButton.snp.bottom)
        make.leading.trailing.equalToSuperview().inset(inset)
      }
    }

    [emptyLabel, tableView].forEach {
      $0.snp.makeConstraints { make in
        make.top.equalTo(searchBar.snp.bottom).offset(inset)
        make.leading.trailing.bottom.equalToSuperview()
      }
    }
  }

  private func applySceneType() {
    switch sceneType {
    case .searh:
      searchBar.becomeFirstResponder()
      searchBar.isHidden = false
      titleLabel.isHidden = true
      emptyLabel.text = "검색 결과가 없습니다."

    case .bookmark:
      searchBar.isHidden = true
      titleLabel.isHidden = false
      emptyLabel.text = "북마크한 지역이 없습니다."
      isHiddenEmptyLabel(dataCount: BookmarkManager.shared.bookmarks.count)
    }
  }

  private func setGesture() {
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissSelf))
    topFadeView.addGestureRecognizer(tapGesture)
  }

  private func requestRegionList(isReset: Bool) {
    if isReset {
      regionList = []
      currentPage = 1
    }

    AddressSearchManager().request(
      from: keyword,
      startPage: currentPage
    ) { [weak self] locations in
      guard let self = self else { return }
      self.regionList += locations
      self.currentPage += 1
      self.tableView.reloadData()
      self.isHiddenEmptyLabel(dataCount: locations.count)
    }
  }

  private func isHiddenEmptyLabel(dataCount: Int) {
    if dataCount == 0 {
      emptyLabel.isHidden = false
    } else {
      emptyLabel.isHidden = true
    }
  }

  @objc func dismissSelf() {
    dismiss(animated: true)
  }
}

extension PresentViewController: UITableViewDataSource, UITableViewDelegate {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if sceneType == .searh {
      return regionList.count
    } else {
      return BookmarkManager.shared.bookmarks.count
    }                                         
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(
      withIdentifier: PresentTableViewCell.identifier
    ) as? PresentTableViewCell else { return UITableViewCell() }

    if sceneType == .searh {
      cell.setupLocation(location: regionList[indexPath.row])
      cell.setupUI()
    } else {
      let bookmarks = BookmarkManager.shared.bookmarks
      cell.setupLocation(location: bookmarks[indexPath.row])
      cell.setupUI()
    }

    return cell
  }

  func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    let currentRow = indexPath.row
    guard (currentRow % display) == (display - 2) && (currentRow / display) == (currentPage - 2) else { return }

    requestRegionList(isReset: false)
  }
}

extension PresentViewController: UISearchBarDelegate {
  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    searchBar.resignFirstResponder()

    guard let searchText = searchBar.text else { return }

    self.keyword = searchText
    requestRegionList(isReset: true)
  }
}

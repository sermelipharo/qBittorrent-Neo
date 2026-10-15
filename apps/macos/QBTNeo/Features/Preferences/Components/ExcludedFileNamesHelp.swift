import Foundation

/// Tooltip of the "Excluded file names" editor (verbatim from qBittorrent).
enum ExcludedFileNamesHelp {
    static let text = String(localized: """
        Blacklist filtered file names from being downloaded from torrent(s).
        Files matching any of the filters in this list will have their priority automatically set to "Do not download".

        Use newlines to separate multiple entries. Can use wildcards as outlined below.
        *: matches zero or more of any characters.
        ?: matches any single character.
        [...]: sets of characters can be represented in square brackets.

        Examples
        *.exe: filter '.exe' file extension.
        readme.txt: filter exact file name.
        ?.txt: filter 'a.txt', 'b.txt' but not 'aa.txt'.
        readme[0-9].txt: filter 'readme1.txt', 'readme2.txt' but not 'readme10.txt'.
        """)
}

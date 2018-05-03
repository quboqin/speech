// Copyright 2016 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Cocoa
import ScreenSaver

let stepDuration = 1.0
let fadeDuration = 0.5

let cellSize:CGFloat = 128.0

let host = "storage.googleapis.com"
let bucket = "gcp-screensaver.appspot.com"

class GCPLifeView: ScreenSaverView {

  var gridViews:[[NSImageView]]!
  var grid:[[Int]]!
  var newgrid:[[Int]]!
  var imageNames:[String]!
  var timer:Timer!
  var history:[String: Int]!

  override init?(frame: NSRect, isPreview: Bool) {
    super.init(frame: frame, isPreview: isPreview)
    startRunning()
  }

  required init?(coder: NSCoder) {
    super.init(coder:coder)
    startRunning()
  }

  override func resizeSubviews(withOldSize oldSize: NSSize) {
    buildGrid()
    randomizeGrid()
    renderGrid()
  }

  override func draw(_ dirtyRect: NSRect) {
    NSColor(white: 0.2, alpha: 1).set()
    NSRectFill(bounds)
  }

  func startRunning() {
    animationTimeInterval = 1/30.0
    // Prepare the display in case there is no network connection.
    buildGrid()
    renderGrid()
    // Fetch the icon list and start animating.
    fetchIconList {
      self.buildGrid()
      self.renderGrid()
      self.timer = Timer.scheduledTimer(timeInterval: stepDuration,
        target: self,
        selector: #selector(self.tick),
        userInfo: nil,
        repeats: true)
    }
  }

  func buildGrid() {
    let bundle = Bundle(for: type(of: self))

    history = [String: Int]()

    if gridViews != nil {
      for views in gridViews {
        for view in views {
          view.removeFromSuperview()
        }
      }
    }
    let cellWidth = cellSize * sqrt(3) / 2

    let centerX = (bounds.size.width - cellSize) * 0.5
    let centerY = (bounds.size.height - cellSize) * 0.5
    let rows:Int = Int(bounds.size.height/cellSize * 0.5 + 0.5)
    let cols:Int = Int(bounds.size.width/cellWidth * 0.5 + 0.5)

    var i:Int = 0

    grid = []
    newgrid = []
    gridViews = []
    for r in -rows...rows {
      grid.append([])
      newgrid.append([])
      gridViews.append([])
      for c in -cols...cols {
        let cellX:CGFloat = centerX + CGFloat(c) * cellSize * sqrt(3) / 2
        var cellY:CGFloat = centerY + CGFloat(r) * cellSize
        let odd:Bool = abs(c) % 2 == 1
        if odd {
          cellY -= 0.5 * cellSize
        }
        let imageFrame = NSRect(x : cellX,
                                y : cellY,
                                width: cellSize,
                                height: cellSize)
        let view = NSImageView.init(frame: imageFrame)
        addSubview(view)
        if r == 0 && c == 0 {
          let imageName = "Logo_Cloud_512px_Retina.png"
          let imagePath = bundle.pathForImageResource(imageName)!
          let image = NSImage.init(contentsOfFile: imagePath)
          view.image = image
          grid[r+rows].append(1)
          newgrid[r+rows].append(1)
          // Expand the logo image slightly to match the product icon sizes.
          let ds = -0.05*cellSize
          view.frame = view.frame.insetBy(dx: ds, dy: ds)
        } else {
          if let imageNames = imageNames {
            let imageName = imageNames[i % imageNames.count]
            i = i + 1
            fetchImage(view, name:imageName)
          }
          grid[r+rows].append(0)
          newgrid[r+rows].append(0)
        }
        gridViews[r+rows].append(view)
      }
    }
  }

  func renderGrid() {
    let rows = grid.count
    let cols = grid[0].count
    for r in 0..<rows {
      for c in 0..<cols {
        let gridView = gridViews[r][c]
        if grid[r][c] == 0 {
          if newgrid[r][c] == 0 {
            gridView.alphaValue = 0
            gridView.isHidden = true
          } else {
            gridView.alphaValue = 0
            gridView.isHidden = false
            NSAnimationContext.runAnimationGroup({ (context) in
              context.duration = fadeDuration
              gridView.animator().alphaValue = 1
              }, completionHandler: {

            })
          }
        } else {
          if newgrid[r][c] == 0 {
            gridView.alphaValue = 1
            NSAnimationContext.runAnimationGroup({ (context) in
              context.duration = fadeDuration
              gridView.animator().alphaValue = 0
              }, completionHandler: {
                gridView.isHidden = true
            })
          } else {
            gridView.isHidden = false
            gridView.alphaValue = 1
          }
        }
      }
    }
  }

  func tick() {
    updateGrid()
    renderGrid()
  }

  func randomizeGrid() {
    history = [String: Int]()
    let rows = grid.count
    let cols = grid[0].count
    for r in 0..<rows {
      for c in 0..<cols {
        let diceRoll = Int(arc4random_uniform(6) + 1)
        if diceRoll > 5  {
          newgrid[r][c] = 1
        } else {
          newgrid[r][c] = 0
        }
        grid[r][c] = 0
      }
    }
    // The center cell should always be alive.
    newgrid[rows/2][cols/2] = 1
    grid[rows/2][cols/2] = 1
  }

  // Compute a signature for the current grid.
  // This will allow us to detect repeats (and cycles).
  func signature() -> String {
    let data = NSMutableData()
    var i = 0
    var v:UInt64 = 0
    let rows = grid.count
    let cols = grid[0].count
    for r in 0..<rows {
      for c in 0..<cols {
        if grid[r][c] != 0 {
          v = v | UInt64(UInt64(1) << UInt64(i))
        }
        i = i + 1
        if i == 64 {
          data.append(&v, length: MemoryLayout.size(ofValue: v))
          i = 0
          v = 0
        }
      }
    }
    if i > 0 {
      data.append(&v, length: MemoryLayout.size(ofValue: v))
    }
    return data.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue:0))
  }

  func updateGrid() {
    // First check for repetitions.
    let s = signature()
    if let x = history[s] {
      if (x == 3) {
        randomizeGrid()
        return
      }
      history[s] = x + 1
    } else {
      history[s] = 1
    }
    // Compute new grid state.
    let rows = grid.count
    let cols = grid[0].count
    grid = newgrid
    newgrid = []
    for r in 0..<rows {
      newgrid.append([])
      for c in 0..<cols {
        // Count the neighbors of cell (r,c).
        var alive = grid[r][c]
        var count = 0
        for rr in -1...1 {
          for cc in -1...1 {
            if rr == 0 && cc == 0 {
              // Don't count the center cell.
            } else {
              // Wrap coordinates around the grid edges.
              var rrr = (r + rr)
              if rrr >= rows {
                rrr = rrr - rows
              } else if rrr < 0 {
                rrr = rrr + rows
              }
              var ccc = (c + cc)
              if ccc >= cols {
                ccc = ccc - cols
              } else if ccc < 0 {
                ccc = ccc + cols
              }
              count += grid[rrr][ccc]
            }
          }
        }
        // Compute the new cell liveness following
        // https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life
        if (alive == 0) {
          if (count == 3) {
          // Any dead cell with exactly three live neighbours becomes a live cell, as if by reproduction.
            alive = 1
          } else {
            alive = 0
          }
        } else {
          if (count == 2) || (count == 3) {
            // Any live cell with two or three live neighbours lives on to the next generation.
            alive = 1
          } else {
            // Any live cell with fewer than two live neighbours dies, as if caused by under-population.
            // Any live cell with more than three live neighbours dies, as if by over-population.
            alive = 0
          }
        }
        // Arbitrarily keep the center cell alive always.
        if r == rows/2 && c == cols/2 {
          alive = 1
        }
        newgrid[r].append(alive)
      }
    }
  }

  func fetchIconList(_ continuation:@escaping ()->()) {
    var urlComponents = URLComponents()
    urlComponents.scheme = "https";
    urlComponents.host = host
    urlComponents.path = "/" + bucket + "/icons.txt"

    if let url = urlComponents.url {
      let request = URLRequest(url:url)
      let session = URLSession.shared
      let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
        if let error = error {
          NSLog("error \(error)")
        }
        else if let data = data {
          DispatchQueue.main.async {
            if let content = String.init(data: data, encoding: String.Encoding.utf8) {
              self.imageNames = content.components(separatedBy: CharacterSet.whitespacesAndNewlines)
              self.imageNames.removeLast()
              continuation()
            }
          }
        } else {
          DispatchQueue.main.async {
            self.imageNames = []
            continuation()
          }
        }
      })
      task.resume()
    }
  }

  func fetchImage(_ imageView:NSImageView, name:String) {
    var urlComponents = URLComponents()
    urlComponents.scheme = "https";
    urlComponents.host = host
    urlComponents.path = "/" + bucket + "/" + name

    if let url = urlComponents.url {
      let request = URLRequest(url:url)
      let session = URLSession.shared
      let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
        if let error = error {
          NSLog("error \(error)")
        }
        else if let data = data {
          DispatchQueue.main.async {
            imageView.image = NSImage(data: data)
          }
        } else {
          NSLog("failed to load \(name)")
          DispatchQueue.main.async {
            imageView.image = nil;
          }
        }
      })
      task.resume()
    }
  }
}

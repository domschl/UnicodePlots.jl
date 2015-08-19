
type Plot{T<:GraphicsArea}
  graphics::T
  title::String
  margin::Int
  padding::Int
  border::Symbol
  leftLabels::Dict{Int,String}
  rightLabels::Dict{Int,String}
  decorations::Dict{Symbol,String}
  showLabels::Bool
end

function Plot{T<:GraphicsArea}(graphics::T;
                         title::String="",
                         margin::Int=3,
                         padding::Int=1,
                         border::Symbol=:solid,
                         showLabels=true)
  rows = nrows(graphics)
  cols = ncols(graphics)
  leftLabels = Dict{Int,String}()
  rightLabels = Dict{Int,String}()
  decorations = Dict{Symbol,String}()
  Plot{T}(graphics, title, margin, padding, border, leftLabels, rightLabels, decorations, showLabels)
end

function setTitle!{T<:GraphicsArea}(plot::Plot{T}, title::String)
  plot.title = title
  plot
end

function annotate!{T<:GraphicsArea}(plot::Plot{T}, where::Symbol, value::String)
  where == :t || where == :b || where == :tl || where == :tr || where == :bl || where == :br || throw(ArgumentError("Unknown location: try one of these :tl :t :tr :bl :b :br"))
  plot.decorations[where] = value
  plot
end

function annotate!{T<:GraphicsArea}(plot::Plot{T}, where::Symbol, row::Int, value::String)
  #0 < row <= nrows(plot.canvas)
  if where == :l
    plot.leftLabels[row] = value
  elseif where == :r
    plot.rightLabels[row] = value
  else
    throw(ArgumentError("Unknown location: try one of these :l :r"))
  end
  plot
end

function drawLine!{T<:Canvas}(plot::Plot{T}, args...; vars...)
  drawLine!(plot.graphics, args...; vars...)
  plot
end

function setPixel!{T<:Canvas}(plot::Plot{T}, args...; vars...)
  setPixel!(plot.graphics, args...; vars...)
  plot
end

function setPoint!{T<:Canvas}(plot::Plot{T}, args...; vars...)
  setPoint!(plot.graphics, args...; vars...)
  plot
end

function show(io::IO, p::Plot)
  b = borderMap[p.border]
  c = p.graphics
  borderLength = ncols(c)

  # get length of largest strings to the left and right
  maxLen = p.showLabels && !isempty(p.leftLabels) ? maximum([length(string(l)) for l in values(p.leftLabels)]) : 0
  maxLenR = p.showLabels && !isempty(p.rightLabels) ? maximum([length(string(l)) for l in values(p.rightLabels)]) : 0

  # offset where the plot (incl border) begins
  plotOffset = maxLen + p.margin + p.padding

  # padding-string from left to border
  plotPadding = repeat(spceStr, p.padding)

  # padding-string between labels and border
  borderPadding = repeat(spceStr, plotOffset)

  # plot the title and the top border
  drawTitle(io, borderPadding, p.title, plotWidth = borderLength)
  if p.showLabels
    topLeftStr = haskey(p.decorations, :tl) ? p.decorations[:tl] : ""
    topMidStr = haskey(p.decorations, :t) ? p.decorations[:t] : ""
    topRightStr = haskey(p.decorations, :tr) ? p.decorations[:tr] : ""
    if topLeftStr != "" || topRightStr != "" || topMidStr != ""
      topLeftLen = length(topLeftStr)
      topMidLen = length(topMidStr)
      topRightLen = length(topRightStr)
      print(io, borderPadding, topLeftStr)
      cnt = safeRound(borderLength / 2 - topMidLen / 2 - topLeftLen)
      pad = cnt > 0 ? repeat(spceStr, cnt) : ""
      print(io, pad, topMidStr)
      cnt = borderLength - topRightLen - topLeftLen - topMidLen + 2 - cnt
      pad = cnt > 0 ? repeat(spceStr, cnt) : ""
      print(io, pad, topRightStr, "\n")
    end
  end
  drawBorderTop(io, borderPadding, borderLength, p.border)
  print(io, repeat(spceStr, maxLenR), plotPadding, "\n")

  # plot all rows
  for row in 1:nrows(c)
    # Current labels to left and right of the row and their length
    tleftLabel = haskey(p.leftLabels,row) ? p.leftLabels[row] : ""
    tRightLabel = haskey(p.rightLabels,row) ? p.rightLabels[row] : ""
    tLen = length(tleftLabel)
    tLenR = length(tRightLabel)
    # print left label
    print(io, repeat(spceStr, p.margin))
    p.showLabels && print(io, repeat(spceStr, maxLen - tLen), tleftLabel)
    # print left border
    print(io, plotPadding, b[:l])
    # print canvas row
    printRow(io, c, row)
    #print right label and padding
    print(io, b[:r])
    p.showLabels && print(io, plotPadding, tRightLabel, repeat(spceStr, maxLenR - tLenR))
    print(io, "\n")
  end

  # draw bottom border and bottom labels
  drawBorderBottom(io, borderPadding, borderLength, p.border)
  print(io, repeat(spceStr, maxLenR), plotPadding, "\n")
  if p.showLabels
    botLeftStr = haskey(p.decorations, :bl) ? p.decorations[:bl] : ""
    botMidStr = haskey(p.decorations, :b) ? p.decorations[:b] : ""
    botRightStr = haskey(p.decorations, :br) ? p.decorations[:br] : ""
    if botLeftStr != "" || botRightStr != "" || botMidStr != ""
      botLeftLen = length(botLeftStr)
      botMidLen = length(botMidStr)
      botRightLen = length(botRightStr)
      print(io, borderPadding, botLeftStr)
      cnt = safeRound(borderLength / 2 - botMidLen / 2 - botLeftLen)
      pad = cnt > 0 ? repeat(spceStr, cnt) : ""
      print(io, pad, botMidStr)
      cnt = borderLength - botRightLen - botLeftLen - botMidLen + 2 - cnt
      pad = cnt > 0 ? repeat(spceStr, cnt) : ""
      print(io, pad, botRightStr, "\n")
    end
  end
end



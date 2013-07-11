//size of the dots
int radius = 10;
int width = 1000;
int height = 1000;
int nbCellsWidth = width / radius;
int nbCellsHeight = height / radius;

int nbActiveCells = 50;
int[][] cells = new int[nbCellsWidth][nbCellsHeight];
int[][] activeCells = new int[nbActiveCells][2];

int minX = 0;
int minY = 0;
int maxX = nbCellsWidth - 1;
int maxY = nbCellsHeight - 1;


//states codes
int STATE_PAUSE = 1;
int STATE_CREATING = 2;
int STATE_CREATED = 3;
int STATE_SMOOTHED = 5;
int STATE_LIFTED = 6;
int STATE_SAVED = 7;
int STATE_ENDED = 8;

int state = STATE_PAUSE;

boolean pause;
boolean displayFull = true;

//color codes
int drawColor = 0;
int seaColor = #000066;
int shoreColor = #EED6AF;
int landColor = #526F35;
int lowMontainColor = #1A1A1A;
int highMontainColor = 0;

void setup()
{
    //  stroke(255);
    frameRate(15);
    size(width, height);
    background(255);
    pause = false;

    //randomly define alive cells
    for (int i = 0 ; i <= maxX ; i ++ ) {
        for (int j = 0 ; j <= maxY ; j ++ ) {
            cells[i][j] = seaColor;
        }
    }

    for (int act = 0 ; act < nbActiveCells ; act++) {
        activeCells[act][0] = int(random(nbCellsWidth));
        activeCells[act][1] = int(random(nbCellsHeight));

        cells[activeCells[act][0]][activeCells[act][1]] = drawColor;
    }
}

void draw()
{
    if (state != STATE_PAUSE) {
        if (state == STATE_CREATING) {
            displayFull = false;
            state = STATE_CREATED;
            //landscaping
            //set new state of the cells
            //foreach active cell
            for (int c = 0 ; c < nbActiveCells ; c ++) {
                int[][] neighbours = _getFreeNeighbours(activeCells[c][0], activeCells[c][1]);
                if (neighbours.length > 0) {
                    state = STATE_CREATING;
                    // Get a random element from an array
                    int index = int(random(neighbours.length));  // same as int(random(4))

                    cells[neighbours[index][0]][neighbours[index][1]] = drawColor;
                    activeCells[c][0] = neighbours[index][0];
                    activeCells[c][1] = neighbours[index][1];
                }
            }
        }
        else if (state == STATE_CREATED) {
            displayFull = true;
            _smooth();
        }
        else if (state == STATE_SMOOTHED) {
            _lift();
            state = STATE_LIFTED;
        }
        else if (state == STATE_LIFTED) {
            _saveFile();
            state = STATE_SAVED;
        }
        else if (state == STATE_SAVED) {
            noLoop(); // Stops the program
            state = STATE_ENDED;
        }

        //display them
        _refreshDisplay(displayFull);
    }
}

void _smooth()
{
    state = STATE_SMOOTHED;
    for (int j = minY ; j <= maxY ; j ++) {
        for (int i = minX ; i <= maxX ; i ++) {
            if (cells[i][j] == seaColor && _isSurrounded(i, j)) {
                cells[i][j] = drawColor;
                state = STATE_CREATED;
                displayFull = true;
            }
        }
    }
}

void _lift()
{
    for (int j = minY ; j <= maxY ; j ++) {
        for (int i = minX ; i <= maxX ; i ++) {
            int distance = _getDistanceFromTheSea(i, j);

            switch (distance) {
                case 0:
                    cells[i][j] = seaColor;
                    break;
                case 1:
                case 2:
                    cells[i][j] = shoreColor;
                    break;
                case 3:
                case 4:
                case 5:
                    cells[i][j] = landColor;
                    break;
                case 6:
                case 7:
                    cells[i][j] = lowMontainColor;
                    break;
                default:
                    cells[i][j] = highMontainColor;
                    break;
            }
        }
    }
}

void _saveFile()
{
    //savefile
    PrintWriter output = createWriter("tiles.txt");
    for (int i = 0 ; i <= maxX ; i ++ ) {
        for (int j = 0 ; j <= maxY ; j ++ ) {
            output.println(i + "    " + j + "    " + hex(cells[i][j])); // Write the coordinate to the file
        }
    }
    output.flush(); // Writes the remaining data to the file
    output.close(); // Finishes the file
}

void _refreshDisplay(boolean full)
{
    int posX;
    int posY;
    //  int diffMouse;

    if (full) {
        for (int j = minY ; j <= maxY ; j ++) {
            for (int i = minX ; i <= maxX ; i ++) {
                posX = i * radius/* - radius / 2*/;
                posY = j * radius/* - radius / 2*/;

                fill(cells[i][j]);

                rect(posX, posY, radius, radius);
            }
        }
    }
    else {
        for (int c = 0 ; c < nbActiveCells ; c ++) {
            posX = activeCells[c][0] * radius/* - radius / 2*/;
            posY = activeCells[c][1] * radius/* - radius / 2*/;
            fill(0);
            rect(posX, posY, radius, radius);
        }
    }
}


int _getDistanceFromTheSea(int i, int j)
{
    if (cells[i][j] == seaColor) {
        return 0;
    }

    boolean seaIsFound = false;

    int minusBound = -1;
    int plusBound = 1;

    while (!seaIsFound) {
        for (int x = minusBound ; x <= plusBound ; x++) {
            for (int y = minusBound ; y <= plusBound ; y++ ) {
                int xPos = x + i;
                int yPos = y + j;
                if (xPos > 0 && xPos <= maxX && yPos > 0 && yPos <= maxY && (x == minusBound || x == plusBound || y == minusBound || y == plusBound) && cells[xPos][yPos] == seaColor) {
                    seaIsFound = true;
                    break;
                }
            }
        }

        minusBound--;
        plusBound++;
    }

    return plusBound;
}

boolean _isSurrounded(int i, int j)
{
    int nbGround = 0;
    int xPos, yPos;

    for (int x = -1 ; x < 2 ; x++ ) {
        for (int y = -1 ; y < 2 ; y++ ) {
            xPos = (x + i) % nbCellsWidth;
            if (xPos < 0) {
                xPos = maxX;
            }
            yPos = (y + j) % nbCellsHeight;
            if (yPos < 0) {
                yPos = maxY;
            }
            if (cells[xPos][yPos] == highMontainColor) {
                nbGround++;
            }
        }
    }

    return (nbGround > 4);
}

int[][] _getFreeNeighbours(int i, int j)
{
    int[][] n = new int[9][2];
    int z = 0;
    int xPos, yPos;

    for (int x = -1 ; x < 2 ; x ++ ) {
        for (int y = -1 ; y < 2 ; y ++ ) {
            xPos = (x + i) % nbCellsWidth;
            if (xPos < 0) {
                xPos = maxX;
            }
            yPos = (y + j) % nbCellsHeight;
            if (yPos < 0) {
                yPos = maxY;
            }
            if (cells[xPos][yPos] == seaColor) {
                n[z][0] = xPos;
                n[z][1] = yPos;
                z++;
            }
        }
    }

    int[][] ret = new int[z][2];

    for (int r = 0 ; r < z ; r++) {
        ret[r][0] = n[r][0];
        ret[r][1] = n[r][1];
    }

    return ret;
}

/**
 * Keyboard events to launch/pause/restart the application
 */
void keyPressed()
{
    if (key == 'r') {
        setup();
    }
    else if (key == '\n') {
        state = STATE_CREATING;
    }
    else if (key == 'p' && state != STATE_ENDED) {
        if (pause) {
            pause = false;
            loop();
        }
        else {
            pause = true;
            noLoop();
        }
    }
}

